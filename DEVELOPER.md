# 开发者指南

本文档面向希望扩展或修改本项目的开发者。

## 架构设计

### 整体架构

```
┌─────────────────────────────────────┐
│           UI Layer (ArkUI)          │
│  ┌─────────────┐   ┌─────────────┐ │
│  │ Index.ets   │   │AddParcel.ets│ │
│  └─────────────┘   └─────────────┘ │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│        Service Layer                │
│  ┌──────────┐  ┌─────────────────┐ │
│  │SmsService│  │ ScanService     │ │
│  └──────────┘  └─────────────────┘ │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│       Database Layer                │
│  ┌────────────────────────────────┐ │
│  │   ParcelDatabase (Singleton)   │ │
│  └────────────────────────────────┘ │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      Data Model Layer               │
│  ┌────────────────────────────────┐ │
│  │       ParcelModel              │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 设计模式

1. **单例模式**
   - `ParcelDatabase` - 数据库管理
   - `SmsService` - 短信服务
   - `ScanService` - 扫码服务

2. **Builder 模式**
   - ArkUI 组件使用 `@Builder` 装饰器
   - 复用 UI 组件

3. **状态管理**
   - `@State` - 组件状态
   - `@Link` - 双向绑定（如需要）

## 核心模块详解

### 1. 数据库模块 (ParcelDatabase)

**职责**：
- 封装所有数据库操作
- 提供 CRUD 接口
- 管理数据库连接

**关键方法**：

```typescript
// 初始化数据库
async initDB(context: Context): Promise<void>

// 插入记录
async insertParcel(parcel: ParcelModel): Promise<number>

// 按状态查询
async queryParcelsByStatus(status: number): Promise<ParcelModel[]>

// 更新状态
async updateParcelStatus(id: number, status: number): Promise<boolean>

// 删除记录（软删除）
async deleteParcel(id: number): Promise<boolean>
```

**扩展示例**：添加按日期范围查询

```typescript
async queryParcelsByDateRange(
  startTime: number, 
  endTime: number
): Promise<ParcelModel[]> {
  if (!this.rdbStore) {
    return [];
  }
  
  const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
  predicates.between('createTime', startTime, endTime)
    .equalTo('isDeleted', Constants.NOT_DELETED)
    .orderByDesc('createTime');
    
  const resultSet = await this.rdbStore.query(predicates);
  return this.convertResultSetToList(resultSet);
}
```

### 2. 短信服务 (SmsService)

**职责**：
- 请求和管理短信权限
- 解析短信内容
- 提取取件码信息

**关键方法**：

```typescript
// 请求权限
async requestPermission(context: Context): Promise<boolean>

// 解析短信内容
parseSmsContent(content: string): ParcelModel | null

// 处理短信
async processSmsContent(content: string): Promise<boolean>
```

**正则表达式**：

```typescript
// 取件码匹配
const pickupCodePattern = /取件码[：:]\s*(\d+-\d+-\d+)/i;

// 驿站匹配
const stationPatterns = [
  /在(.+?驿站)/,
  /(.+?驿站)/,
  /在(.+?超市)/
];

// 快递公司匹配（使用配置的关键词）
const regex = new RegExp(company.keyword, 'i');
```

**扩展示例**：支持更多取件码格式

```typescript
parseSmsContent(content: string): ParcelModel | null {
  // 现有格式：2-5-2418
  let pickupCode = '';
  
  // 格式1: X-X-XXXX
  let pattern = /取件码[：:]\s*(\d+-\d+-\d+)/i;
  let match = content.match(pattern);
  
  if (!match) {
    // 格式2: XXXXXX (6位数字)
    pattern = /取件码[：:]\s*(\d{6})/i;
    match = content.match(pattern);
  }
  
  if (!match) {
    // 格式3: 自定义格式
    pattern = /取件码[：:]\s*([A-Z0-9]+)/i;
    match = content.match(pattern);
  }
  
  if (match) {
    pickupCode = match[1];
    // 继续处理...
  }
  
  return null;
}
```

### 3. 扫码服务 (ScanService)

**职责**：
- 启动扫码界面
- 处理扫码结果
- 解析条形码/二维码内容

**关键方法**：

```typescript
// 启动扫码
async startScan(context: Context): Promise<void>

// 处理扫码结果
async processScanResult(content: string): Promise<void>

// 解析条形码
private parseBarcode(content: string): ParcelModel | null
```

**扩展示例**：支持特定快递公司的二维码格式

```typescript
private parseBarcode(content: string): ParcelModel | null {
  // 检查是否为京东快递二维码
  if (content.startsWith('JD:')) {
    return this.parseJDBarcode(content);
  }
  
  // 检查是否为顺丰快递二维码
  if (content.includes('SF_EXPRESS')) {
    return this.parseSFBarcode(content);
  }
  
  // 通用格式
  return this.parseGenericBarcode(content);
}

private parseJDBarcode(content: string): ParcelModel | null {
  // 京东格式: JD:取件码:驿站:地址
  const parts = content.split(':');
  if (parts.length >= 2) {
    return new ParcelModel(
      parts[1],
      '京东快递',
      parts[2] || '驿站',
      parts[3] || '',
      DateUtils.getCurrentTime(),
      Constants.STATUS_PENDING
    );
  }
  return null;
}
```

## UI 开发指南

### 组件结构

主页面 (`Index.ets`) 采用 `@Builder` 模式构建可复用组件：

```typescript
@Entry
@Component
struct Index {
  build() {
    Column() {
      this.TopBar()         // 顶部导航栏
      this.FilterBar()      // 筛选区
      this.ParcelList()     // 列表区
      this.BottomTabBar()   // 底部导航
    }
  }
  
  @Builder TopBar() { }
  @Builder FilterBar() { }
  @Builder ParcelList() { }
  @Builder ParcelCard(parcel: ParcelModel) { }
  @Builder BottomTabBar() { }
}
```

### 添加新的 UI 组件

**示例**：添加搜索框

```typescript
@Builder
SearchBar() {
  Row() {
    TextInput({ placeholder: '搜索取件码、驿站名称' })
      .width('100%')
      .height(40)
      .borderRadius(20)
      .backgroundColor($r('app.color.filter_button_bg'))
      .padding({ left: 16, right: 16 })
      .onChange((value: string) => {
        this.onSearch(value);
      })
  }
  .width('100%')
  .padding(16)
  .backgroundColor(Color.White)
}

// 搜索处理
onSearch(keyword: string) {
  if (!keyword) {
    this.loadParcels();
    return;
  }
  
  this.parcelList = this.parcelList.filter(parcel => 
    parcel.pickupCode.includes(keyword) ||
    parcel.stationName.includes(keyword) ||
    parcel.courierCompany.includes(keyword)
  );
}
```

### 状态管理

使用 `@State` 管理组件状态：

```typescript
@State currentTab: number = 0;           // 当前标签页
@State parcelList: ParcelModel[] = [];   // 包裹列表
@State selectedFilter: string = '按时间'; // 选中的筛选项
@State isLoading: boolean = false;       // 加载状态
```

**注意事项**：
- `@State` 变量改变会触发 UI 更新
- 复杂对象需要重新赋值才能触发更新
- 使用扩展运算符或 `Array.slice()` 创建新引用

## 数据库扩展

### 添加新字段

1. **修改表结构**

编辑 `ParcelDatabase.ets` 的 `createTable()` 方法：

```typescript
private async createTable(): Promise<void> {
  const createTableSql = `
    CREATE TABLE IF NOT EXISTS ${Constants.TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pickupCode TEXT NOT NULL,
      courierCompany TEXT NOT NULL,
      stationName TEXT NOT NULL,
      address TEXT,
      pickupTime TEXT,
      status INTEGER DEFAULT 0,
      createTime INTEGER,
      isDeleted INTEGER DEFAULT 0,
      syncStatus INTEGER DEFAULT 0,
      // 新字段
      phoneNumber TEXT,           -- 联系电话
      notes TEXT,                 -- 备注
      expiryTime INTEGER,         -- 过期时间
      reminderSet INTEGER DEFAULT 0  -- 是否设置提醒
    )
  `;
  
  await this.rdbStore.executeSql(createTableSql);
}
```

2. **更新数据模型**

编辑 `ParcelModel.ets`：

```typescript
export class ParcelModel {
  // 现有字段...
  
  // 新字段
  phoneNumber?: string;
  notes?: string;
  expiryTime?: number;
  reminderSet?: number;
  
  constructor(...) {
    // 现有构造函数...
    this.phoneNumber = '';
    this.notes = '';
    this.expiryTime = 0;
    this.reminderSet = 0;
  }
}
```

3. **更新数据库操作**

```typescript
async insertParcel(parcel: ParcelModel): Promise<number> {
  const valueBucket: relationalStore.ValuesBucket = {
    // 现有字段...
    'phoneNumber': parcel.phoneNumber,
    'notes': parcel.notes,
    'expiryTime': parcel.expiryTime,
    'reminderSet': parcel.reminderSet
  };
  
  return await this.rdbStore.insert(Constants.TABLE_NAME, valueBucket);
}
```

### 数据库迁移

处理版本升级：

```typescript
async initDB(context: Context): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: Constants.DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1
  };
  
  this.rdbStore = await relationalStore.getRdbStore(context, config);
  
  // 检查版本
  const version = await this.getDBVersion();
  if (version < Constants.DB_VERSION) {
    await this.migrateDatabase(version, Constants.DB_VERSION);
  }
  
  await this.createTable();
}

private async migrateDatabase(oldVersion: number, newVersion: number): Promise<void> {
  console.info(`Migrating database from ${oldVersion} to ${newVersion}`);
  
  // v1 -> v2: 添加 phoneNumber 字段
  if (oldVersion < 2) {
    await this.rdbStore.executeSql(
      `ALTER TABLE ${Constants.TABLE_NAME} ADD COLUMN phoneNumber TEXT`
    );
  }
  
  // v2 -> v3: 添加 notes 字段
  if (oldVersion < 3) {
    await this.rdbStore.executeSql(
      `ALTER TABLE ${Constants.TABLE_NAME} ADD COLUMN notes TEXT`
    );
  }
}
```

## 添加新功能

### 示例：添加取件提醒功能

#### 1. 更新数据模型

```typescript
// ParcelModel.ets
export class ParcelModel {
  reminderTime?: number;  // 提醒时间戳
  isReminderEnabled?: boolean;  // 是否启用提醒
}
```

#### 2. 创建提醒服务

```typescript
// service/ReminderService.ets
import reminderAgentManager from '@ohos.reminderAgentManager';

export class ReminderService {
  async setReminder(parcel: ParcelModel, reminderTime: number): Promise<boolean> {
    const reminderRequest: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: new Date(reminderTime).getHours(),
      minute: new Date(reminderTime).getMinutes(),
      title: '取件提醒',
      content: `您有快递待取：${parcel.pickupCode}`,
      actionButton: [
        {
          title: '查看',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM
        }
      ]
    };
    
    try {
      const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
      return true;
    } catch (error) {
      console.error('Set reminder failed:', JSON.stringify(error));
      return false;
    }
  }
}
```

#### 3. 添加 UI

```typescript
// 在 AddParcel.ets 中添加提醒时间选择
@State reminderTime: Date = new Date();
@State enableReminder: boolean = false;

@Builder
ReminderSection() {
  Column() {
    Row() {
      Text('设置提醒')
      Toggle({ type: ToggleType.Switch, isOn: this.enableReminder })
        .onChange((isOn: boolean) => {
          this.enableReminder = isOn;
        })
    }
    
    if (this.enableReminder) {
      DatePicker({
        selected: this.reminderTime
      })
        .onChange((value: DatePickerResult) => {
          // 更新提醒时间
        })
    }
  }
}
```

## 测试

### 单元测试示例

```typescript
// test/ParcelDatabase.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { ParcelModel } from '../model/ParcelModel';

export default function parcelDatabaseTest() {
  describe('ParcelDatabase', () => {
    it('should insert parcel successfully', async () => {
      const db = ParcelDatabase.getInstance();
      const parcel = new ParcelModel(
        '1-2-3456',
        '测试快递',
        '测试驿站',
        '测试地址',
        '12:00',
        0
      );
      
      const id = await db.insertParcel(parcel);
      expect(id).assertLarger(0);
    });
    
    it('should query parcels by status', async () => {
      const db = ParcelDatabase.getInstance();
      const parcels = await db.queryParcelsByStatus(0);
      expect(parcels.length).assertLargerOrEqual(0);
    });
  });
}
```

## 性能优化建议

1. **列表优化**
   - 使用 `LazyForEach` 代替 `ForEach`
   - 实现虚拟滚动

2. **数据库优化**
   - 添加索引：`CREATE INDEX idx_status ON parcel_records(status)`
   - 使用事务批量操作

3. **图片优化**
   - 使用 WebP 格式
   - 压缩图片大小

4. **内存管理**
   - 及时释放大对象
   - 避免内存泄漏

## 调试技巧

### 日志输出

```typescript
console.info('信息日志');
console.error('错误日志:', JSON.stringify(error));
console.debug('调试日志:', data);
```

### 断点调试

在 DevEco Studio 中：
1. 设置断点
2. 以 Debug 模式运行
3. 查看变量值

### 性能分析

使用 HiLog 和 HiTrace 进行性能分析。

## 代码规范

1. **命名规范**
   - 类名：PascalCase（如 `ParcelModel`）
   - 方法名：camelCase（如 `loadParcels`）
   - 常量：UPPER_SNAKE_CASE（如 `DB_NAME`）

2. **注释规范**
   - 类和方法添加 JSDoc 注释
   - 关键逻辑添加行内注释

3. **代码格式**
   - 使用 2 空格缩进
   - 单行不超过 120 字符

## 资源

- [HarmonyOS 开发文档](https://developer.harmonyos.com/)
- [ArkTS 语言规范](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkts-get-started-0000001504769321)
- [ArkUI 组件参考](https://developer.harmonyos.com/cn/docs/documentation/doc-references/ts-components-summary-0000001544697109)

---

**祝开发愉快！**

