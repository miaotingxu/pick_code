# 快递取件码管理 APP - 完整开发计划

**项目名称**: 快递取件码管理 HarmonyOS 应用  
**创建时间**: 2025-10-22  
**当前版本**: v1.0.0  
**状态**: ✅ v1.0.0 已完成

---

## 一、数据模型设计

### 1. 数据库表结构（关系型数据库）

#### ParcelRecord 表 ✅ 已完成

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | INTEGER | 主键 | PRIMARY KEY, AUTOINCREMENT |
| pickupCode | TEXT | 取件码（如 "2-5-2418"） | NOT NULL |
| courierCompany | TEXT | 快递公司（圆通、中通、极兔、京东等） | NOT NULL |
| stationName | TEXT | 驿站名称 | NOT NULL |
| address | TEXT | 详细地址 | |
| pickupTime | TEXT | 取件时间 | |
| status | INTEGER | 状态（0-待取，1-已取） | DEFAULT 0 |
| createTime | INTEGER | 创建时间戳 | |
| isDeleted | INTEGER | 删除标记（0-未删除，1-已删除） | DEFAULT 0 |
| syncStatus | INTEGER | 同步状态（0-未同步，1-已同步，预留云端同步） | DEFAULT 0 |

#### 表创建 SQL
```sql
CREATE TABLE IF NOT EXISTS parcel_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pickupCode TEXT NOT NULL,
  courierCompany TEXT NOT NULL,
  stationName TEXT NOT NULL,
  address TEXT,
  pickupTime TEXT,
  status INTEGER DEFAULT 0,
  createTime INTEGER,
  isDeleted INTEGER DEFAULT 0,
  syncStatus INTEGER DEFAULT 0
)
```

### 2. 数据管理层 ✅ 已完成

#### 文件结构
- ✅ `database/ParcelDatabase.ets` - 数据库操作封装
- ✅ `model/ParcelModel.ets` - 数据模型定义
- ✅ `common/Constants.ets` - 常量配置

#### 核心接口
- ✅ `initDB()` - 初始化数据库
- ✅ `insertParcel()` - 插入包裹记录
- ✅ `queryParcelsByStatus()` - 按状态查询
- ✅ `queryParcelsByCompany()` - 按快递公司查询
- ✅ `updateParcelStatus()` - 更新包裹状态
- ✅ `deleteParcel()` - 软删除包裹
- ✅ `batchDeleteParcels()` - 批量删除

#### 设计模式
- ✅ 单例模式（Singleton）
- ✅ 软删除机制
- ✅ 预留云端同步接口

---

## 二、核心功能实现

### 1. 短信/通知读取功能 ✅ 已完成

#### 权限申请
- ✅ `ohos.permission.READ_MESSAGES` 权限配置
- ✅ 动态权限申请流程
- ✅ 权限说明文案

#### 短信解析服务 (`service/SmsService.ets`)
- ✅ 正则匹配取件码格式
  ```typescript
  /取件码[：:]\s*(\d+-\d+-\d+)/i
  ```
- ✅ 识别快递公司关键词（11 家快递公司）
  - 圆通、中通、极兔、京东、韵达
  - 菜鸟、妈妈驿站、免喜生活
  - 顺丰、申通、邮政
- ✅ 自动提取驿站名称
- ✅ 自动提取地址信息
- ✅ 手动处理短信内容接口

#### 实现文件
- `entry/src/main/ets/service/SmsService.ets`
- `entry/src/main/module.json5` (权限配置)

### 2. 手动添加功能 ✅ 已完成

#### 添加页面 (`pages/AddParcel.ets`)
- ✅ 表单式输入界面
- ✅ 快递公司选择器（底部弹窗）
- ✅ 驿站名称输入
- ✅ 地址输入
- ✅ 取件码输入
- ✅ 输入验证
- ✅ 保存到数据库
- ✅ Toast 提示反馈

#### 字段列表
1. 快递公司（必填）- 选择器
2. 驿站名称（必填）- 文本输入
3. 取件码（必填）- 文本输入
4. 地址（选填）- 文本输入

### 3. 扫码功能 ✅ 已完成

#### 扫码服务 (`service/ScanService.ets`)
- ✅ 集成 `scanBarcode` API
- ✅ 二维码扫描
- ✅ 条形码扫描
- ✅ 相册扫码支持
- ✅ 自动解析扫码结果
- ✅ 提取取件码信息
- ✅ 识别快递公司

#### 支持的格式
- QR Code (二维码)
- Bar Code (条形码)

---

## 三、UI 页面开发

### 1. 主页面 - 取件记录列表 ✅ 已完成
**文件**: `pages/Index.ets`

#### 布局结构

```
┌─────────────────────────────────────┐
│ ☰  待取包裹(3)          +  ⊞  🗑  │ 顶部导航栏
├─────────────────────────────────────┤
│ [按时间] [免喜] [妈妈] [韵达]  ☑   │ 筛选区（仅待取页面）
├─────────────────────────────────────┤
│ 04-28                      4条记录   │ 日期分组头
│ ┌─────────────────────────────────┐ │
│ │ [YT] 菜鸟驿站         17:45  ○ │ │ 包裹卡片
│ │      杭州万泰凤华新建店          │ │
│ │      2-5-2418                   │ │ 取件码（大号）
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [ZT] 菜鸟驿站         17:37  ○ │ │
│ │      杭州万泰凤华新建店          │ │
│ │      6-2-2175                   │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│       📦           ✓                │ 底部 TabBar
│      待取          已取              │
└─────────────────────────────────────┘
```

#### 功能区组件

**顶部导航栏** ✅
- 左上角：菜单按钮（预留）
- 标题：
  - 待取页面："待取包裹(数量)"
  - 已取页面："取件记录"
- 右上角：
  - 添加按钮（+）
  - 扫码按钮（⊞）
  - 删除按钮（已取页面显示）

**筛选区** ✅（仅待取页面显示）
- 筛选按钮组：
  - [按时间] - 默认选中（黑色背景/白字）
  - [免喜] - 未选中（灰色背景/灰字）
  - [妈妈] - 未选中
  - [韵达] - 未选中
- 勾选框（右侧）

**列表区** ✅
- 日期分组头：
  - 左侧：日期（如"04-28"）
  - 右侧：记录数量
- 卡片列表：
  - 白色圆角卡片（border-radius: 16px）
  - 卡片阴影效果
  - 左侧：快递公司图标（圆形，48x48）
  - 中间：
    - 驿站名称（粗体，16px）
    - 地址（灰色，12px）
    - 取件码（粗体，28px，字母间距）
  - 右侧：
    - 时间（12px）
    - 状态图标：
      - 待取：空心圆圈
      - 已取：蓝色实心圆+白色勾

**底部 TabBar** ✅
- 待取标签（左）
  - 图标：📦
  - 文字：待取
  - 选中态：黑色粗体
- 已取标签（右）
  - 图标：✓
  - 文字：已取
  - 选中态：黑色粗体

#### 交互功能 ✅

1. **长按取件码复制** ✅
   - 使用 `LongPressGesture`
   - 调用 `pasteboard` API
   - Toast 提示"取件码已复制"

2. **点击勾选框切换状态** ✅
   - 更新数据库状态
   - 刷新页面数据
   - 动画过渡

3. **筛选按钮切换** ✅
   - 选中态：黑色背景 + 白色文字
   - 未选中：灰色背景 + 灰色文字
   - 实时过滤列表

4. **删除功能** ✅
   - 进入编辑模式
   - 多选删除
   - 软删除机制

5. **页面刷新** ✅
   - 添加后自动刷新
   - 扫码后自动刷新
   - 状态切换后自动刷新

### 2. 快递公司图标资源

#### 支持的快递公司 ✅（11 家）

| 快递公司 | 英文标识 | 缩写 | 颜色 | 图标方案 |
|---------|---------|------|------|----------|
| 圆通速递 | YTO | YT | #FF6B6B | 文字图标 |
| 中通快递 | ZTO | ZT | #4ECDC4 | 文字图标 |
| 极兔速递 | J&T | JT | #95E1D3 | 文字图标 |
| 京东快递 | JD | JD | #E53935 | 文字图标 |
| 韵达快递 | YUNDA | YD | #9B59B6 | 文字图标 |
| 菜鸟驿站 | CAINIAO | CN | #FF9800 | 文字图标 |
| 妈妈驿站 | MAMA | MM | #E91E63 | 文字图标 |
| 免喜生活 | MIANXI | MX | #2196F3 | 文字图标 |
| 顺丰速运 | SF | SF | #4CAF50 | 文字图标 |
| 申通快递 | STO | ST | #FFC107 | 文字图标 |
| 邮政快递 | EMS | EMS | #00BCD4 | 文字图标 |

#### 图标实现方式
- ✅ **当前方案**: 彩色文字图标
  - 圆形背景 + 品牌色
  - 白色缩写文字
  - 无需额外资源
  - 易于扩展新快递公司

- 📋 **可选方案**: 真实 Logo
  - 存放路径: `entry/src/main/resources/base/media/`
  - 格式: PNG (支持透明)
  - 尺寸: 128x128px
  - 参考文档: `ICONS_README.md`

### 3. 颜色和样式规范 ✅ 已完成

#### 颜色定义 (`resources/base/element/color.json`)

```json
{
  "color": [
    { "name": "background_color", "value": "#F5F5F5" },
    { "name": "card_background", "value": "#FFFFFF" },
    { "name": "primary_text", "value": "#000000" },
    { "name": "secondary_text", "value": "#999999" },
    { "name": "accent_blue", "value": "#007AFF" },
    { "name": "accent_green", "value": "#00C853" },
    { "name": "divider_color", "value": "#E5E5E5" },
    { "name": "filter_button_bg", "value": "#F0F0F0" },
    { "name": "filter_button_active_bg", "value": "#000000" },
    { "name": "filter_button_text", "value": "#666666" },
    { "name": "filter_button_active_text", "value": "#FFFFFF" }
  ]
}
```

#### 样式规范

| 元素 | 样式 |
|------|------|
| 主题色 | 黑色 (#000000) |
| 选中色 | 黑色背景 (#000000) + 白色文字 |
| 已取标记 | 蓝色 (#007AFF) |
| 背景色 | 浅灰 (#F5F5F5) |
| 卡片背景 | 白色 (#FFFFFF) |
| 卡片圆角 | 16px |
| 标题字体 | 粗体、16px |
| 取件码字体 | 粗体、28px、字母间距 2px |
| 地址字体 | 常规、12px、灰色 |

---

## 四、关键文件清单

### 已完成文件 ✅（13 个核心文件）

#### 页面文件（2 个）
1. ✅ `entry/src/main/ets/pages/Index.ets` - 主页面（~370 行）
2. ✅ `entry/src/main/ets/pages/AddParcel.ets` - 添加页面（~140 行）

#### 数据层文件（2 个）
3. ✅ `entry/src/main/ets/database/ParcelDatabase.ets` - 数据库管理（~250 行）
4. ✅ `entry/src/main/ets/model/ParcelModel.ets` - 数据模型（~50 行）

#### 服务层文件（2 个）
5. ✅ `entry/src/main/ets/service/SmsService.ets` - 短信读取服务（~150 行）
6. ✅ `entry/src/main/ets/service/ScanService.ets` - 扫码服务（~120 行）

#### 工具类文件（2 个）
7. ✅ `entry/src/main/ets/utils/IconUtils.ets` - 图标工具（~60 行）
8. ✅ `entry/src/main/ets/utils/DateUtils.ets` - 日期工具（~80 行）

#### 配置文件（5 个）
9. ✅ `entry/src/main/ets/common/Constants.ets` - 常量配置（~100 行）
10. ✅ `entry/src/main/resources/base/element/color.json` - 颜色资源
11. ✅ `entry/src/main/resources/base/element/string.json` - 字符串资源
12. ✅ `entry/src/main/resources/base/profile/main_pages.json` - 路由配置
13. ✅ `entry/src/main/module.json5` - 模块配置（权限）

### 文档文件（6 个）
1. ✅ `README.md` - 项目说明文档
2. ✅ `QUICKSTART.md` - 快速开始指南
3. ✅ `DEVELOPER.md` - 开发者指南
4. ✅ `ICONS_README.md` - 图标使用指南
5. ✅ `CHANGELOG.md` - 版本更新日志
6. ✅ `PROJECT_SUMMARY.md` - 项目完成总结

---

## 五、开发步骤与进度

### Phase 1: 基础架构搭建 ✅ 已完成

#### 1.1 数据层搭建 ✅
- [x] 创建数据模型 `ParcelModel`
- [x] 创建数据库管理类 `ParcelDatabase`
- [x] 创建常量配置 `Constants`
- [x] 定义 11 家快递公司信息
- [x] 设计表结构和索引

#### 1.2 资源配置 ✅
- [x] 添加颜色资源（12 种颜色）
- [x] 添加字符串资源（18 个字符串）
- [x] 配置路由
- [x] 配置权限

### Phase 2: UI 组件开发 ✅ 已完成

#### 2.1 主列表页面 ✅
- [x] 顶部导航栏组件
- [x] 筛选区组件
- [x] 列表组件（按日期分组）
- [x] 卡片组件（包裹信息卡片）
- [x] 底部 TabBar 组件
- [x] 状态管理（@State）

#### 2.2 添加页面 ✅
- [x] 表单布局
- [x] 快递公司选择器（底部弹窗）
- [x] 输入框组件
- [x] 保存逻辑

#### 2.3 图标系统 ✅
- [x] 彩色文字图标实现
- [x] IconUtils 工具类
- [x] 颜色映射
- [x] 缩写生成

### Phase 3: 核心功能实现 ✅ 已完成

#### 3.1 数据操作 ✅
- [x] 插入包裹记录
- [x] 查询包裹列表
- [x] 按状态筛选
- [x] 按快递公司筛选
- [x] 更新包裹状态
- [x] 软删除包裹
- [x] 批量删除

#### 3.2 权限与短信读取 ✅
- [x] 短信权限申请流程
- [x] 权限检查
- [x] 短信内容解析
- [x] 正则匹配取件码
- [x] 快递公司识别
- [x] 驿站信息提取

#### 3.3 交互功能 ✅
- [x] 长按复制取件码
- [x] 点击切换状态
- [x] 筛选切换
- [x] 批量删除
- [x] Toast 提示

#### 3.4 扫码功能 ✅
- [x] 集成 scanBarcode API
- [x] 二维码扫描
- [x] 条形码扫描
- [x] 扫码结果解析
- [x] 自动添加包裹

### Phase 4: 数据联调 ✅ 已完成

#### 4.1 UI 与数据库联通 ✅
- [x] 页面初始化加载数据
- [x] 添加后刷新列表
- [x] 状态切换后更新
- [x] 删除后刷新
- [x] 扫码后刷新

#### 4.2 测试数据 ✅
- [x] 创建测试数据（4 条）
- [x] 首次运行自动加载

### Phase 5: 优化完善 ✅ 已完成

#### 5.1 性能优化 ✅
- [x] 数据库单例模式
- [x] 结果集及时关闭
- [x] 避免内存泄漏

#### 5.2 异常处理 ✅
- [x] 数据库操作异常捕获
- [x] 权限拒绝处理
- [x] 扫码失败处理
- [x] 输入验证

#### 5.3 用户体验 ✅
- [x] Toast 提示反馈
- [x] 加载状态处理
- [x] 空状态处理
- [x] 动画效果

#### 5.4 文档完善 ✅
- [x] README 项目说明
- [x] QUICKSTART 快速开始
- [x] DEVELOPER 开发指南
- [x] ICONS_README 图标指南
- [x] CHANGELOG 更新日志
- [x] PROJECT_SUMMARY 项目总结

---

## 六、技术栈与工具

### 开发环境
- **IDE**: DevEco Studio 4.0+
- **SDK**: HarmonyOS SDK API 9+
- **语言**: ArkTS (TypeScript 扩展)
- **设备**: 手机/平板

### 核心 API
| API | 用途 | 文件 |
|-----|------|------|
| `relationalStore` | 关系型数据库 | ParcelDatabase.ets |
| `scanBarcode` | 扫码功能 | ScanService.ets |
| `abilityAccessCtrl` | 权限管理 | SmsService.ets |
| `pasteboard` | 剪贴板 | Index.ets |
| `router` | 路由导航 | Index.ets, AddParcel.ets |
| `promptAction` | Toast 提示 | 各页面 |

### UI 组件
- `Column`, `Row` - 布局
- `List`, `ListItem`, `ListItemGroup` - 列表
- `Text`, `TextInput` - 文本
- `Image`, `Circle` - 图形
- `Button`, `Checkbox`, `Toggle` - 交互
- `Stack` - 层叠布局

### 设计模式
- **单例模式**: 数据库、服务类
- **Builder 模式**: UI 组件复用
- **状态管理**: `@State` 响应式

---

## 七、待优化功能（未来版本）

### v1.1.0 计划 📋

#### 功能增强
- [ ] **取件提醒通知**
  - 基于时间的提醒
  - 过期提醒
  - 通知管理
  - 文件: `service/ReminderService.ets`

- [ ] **深色模式**
  - 完整 UI 适配
  - 自动/手动切换
  - 颜色主题切换

- [ ] **搜索功能**
  - 按取件码搜索
  - 按驿站名称搜索
  - 按快递公司搜索
  - 实时搜索结果

#### UI 优化
- [ ] **真实快递公司 Logo**
  - 准备官方图标资源
  - 替换文字图标
  - 参考: `ICONS_README.md`

- [ ] **动画效果**
  - 页面切换动画
  - 卡片展开动画
  - 状态切换动画

- [ ] **手势操作**
  - 左滑删除
  - 下拉刷新
  - 上拉加载

### v1.2.0 计划 📋

#### 云端功能
- [ ] **云端同步**
  - 实现后端服务
  - 数据同步接口
  - 多设备同步
  - 冲突处理

- [ ] **账号系统**
  - 用户注册/登录
  - 数据隔离
  - 权限管理

#### 数据功能
- [ ] **数据导出/导入**
  - JSON 格式导出
  - Excel 导出
  - 数据备份
  - 数据恢复

- [ ] **统计分析**
  - 取件历史统计
  - 快递公司使用频率
  - 驿站使用频率
  - 可视化图表

#### 高级功能
- [ ] **批量操作**
  - 批量标记已取
  - 批量分享
  - 批量导出

- [ ] **自定义设置**
  - 自动删除已取记录（N 天后）
  - 默认筛选条件
  - 显示设置

---

## 八、性能指标

### 目标指标
- 应用启动时间: < 2s
- 页面切换延迟: < 300ms
- 数据库查询: < 100ms
- 列表滚动: 60fps

### 优化方案
- 使用 LazyForEach 懒加载
- 图片资源压缩
- 数据库索引优化
- 避免频繁 UI 刷新

---

## 九、测试计划

### 单元测试
- [ ] 数据库 CRUD 测试
- [ ] 短信解析测试
- [ ] 数据模型测试

### 集成测试
- [ ] 添加流程测试
- [ ] 状态切换测试
- [ ] 删除流程测试

### UI 测试
- [ ] 页面渲染测试
- [ ] 交互响应测试
- [ ] 边界情况测试

---

## 十、发布清单

### v1.0.0 发布准备 ✅
- [x] 功能开发完成
- [x] 代码无 Linter 错误
- [x] 文档完善
- [x] 测试数据准备
- [x] 应用图标
- [x] 启动页

### 发布渠道
- HarmonyOS 应用市场
- 企业内部分发
- 开源社区

---

## 附录

### A. 快递公司关键词映射表

| 快递公司 | 匹配关键词（正则） | 优先级 |
|---------|------------------|--------|
| 圆通速递 | `圆通\|YTO\|yto` | 高 |
| 中通快递 | `中通\|ZTO\|zto` | 高 |
| 极兔速递 | `极兔\|J&T\|JT\|jt` | 高 |
| 京东快递 | `京东\|JD\|jd` | 高 |
| 韵达快递 | `韵达\|YUNDA\|yunda` | 高 |
| 菜鸟驿站 | `菜鸟\|cainiao` | 高 |
| 妈妈驿站 | `妈妈驿站\|妈妈` | 中 |
| 免喜生活 | `免喜\|免费\|达凯尔多斯` | 中 |
| 顺丰速运 | `顺丰\|SF\|sf` | 高 |
| 申通快递 | `申通\|STO\|sto` | 高 |
| 邮政快递 | `邮政\|EMS\|ems` | 高 |

### B. 取件码格式示例

- 格式 1: `2-5-2418` (数字-数字-数字)
- 格式 2: `8-8-2288` (数字-数字-数字)
- 格式 3: `6-2-2175` (数字-数字-数字)
- 扩展格式: `ABCD-1234`, `123456` 等

### C. 参考资源

- [HarmonyOS 开发文档](https://developer.harmonyos.com/)
- [ArkTS 语言规范](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkts-get-started-0000001504769321)
- [RelationalStore API](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-apis-data-relationalstore-0000001478181625)
- [ScanBarcode API](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-apis-scanbarcode-0000001821000745)

---

**文档版本**: 1.0  
**最后更新**: 2025-10-22  
**维护者**: 开发团队

---

## 使用说明

本文档为快递取件码管理 APP 的完整开发计划，包含：

1. **已完成内容** - 标注 ✅
2. **待开发内容** - 标注 📋 或 [ ]
3. **技术细节** - 文件路径、代码示例
4. **扩展方向** - 未来版本计划

建议配合以下文档阅读：
- `README.md` - 了解项目功能
- `QUICKSTART.md` - 快速开始开发
- `DEVELOPER.md` - 深入开发指南
- `PROJECT_SUMMARY.md` - 查看完成情况

