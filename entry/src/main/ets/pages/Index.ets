import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import { ScanService } from '../service/ScanService';
import { IconUtils } from '../utils/IconUtils';
import { router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State currentTab: number = 0; // 0-待取, 1-已取
  @State parcelList: ParcelModel[] = [];
  @State selectedSortMode: string = '按时间'; // 排序模式：'按时间' 或 '按快递公司'
  @State isEditMode: boolean = false;
  @State selectedParcels: Set<number> = new Set();
  @State groupedData: Map<string, ParcelModel[]> = new Map();
  private database: ParcelDatabase = ParcelDatabase.getInstance();
  private scanService: ScanService = ScanService.getInstance();
  private companySortOrder: string[] = []; // 保存快递公司的排序顺序

  async aboutToAppear() {
    // 初始化数据库
    const context = getContext(this) as common.UIAbilityContext;
    await this.database.initDB(context);
    // 加载测试数据（首次运行时）
    await this.loadTestData();
    // 加载数据
    await this.loadParcels();
  }

  // 页面显示时刷新
  async onPageShow() {
    await this.loadParcels();
  }

  // 加载测试数据
  async loadTestData() {
    const existingData = await this.database.queryAllParcels();
    
    // 临时强制加载测试数据（测试完记得改回来！）
    if (existingData.length > 0) {
      console.info('检测到已有数据，先清空旧数据');
      // 删除所有旧数据
      for (const parcel of existingData) {
        if (parcel.id) {
          await this.database.deleteParcel(parcel.id);
        }
      }
    }
    
    // 添加丰富的测试数据（每个快递公司数量不同，方便测试排序功能）
    // 将 pickupTime 转换为今天对应时刻的时间戳
    const convertTimeToTimestamp = (timeStr: string): number => {
      const parts = timeStr.split(':');
      const hour = parseInt(parts[0]);
      const minute = parseInt(parts[1]);
      const now = new Date();
      now.setHours(hour, minute, 0, 0);
      return now.getTime();
    };
    
    const testParcels = [
        // 顺丰速运 (2件)
        new ParcelModel('SF1234567890', '顺丰速运', '顺丰站点', '杭州文三路营业点', '18:45', 0),
        new ParcelModel('SF1234567891', '顺丰速运', '顺丰站点', '杭州文三路营业点', '17:55', 0),
        
        // 中通快递 (5件 - 数量最多)
        new ParcelModel('6-2-2175', '中通快递', '菜鸟驿站', '杭州万泰凤华新建店', '18:30', 0),
        new ParcelModel('6-2-2176', '中通快递', '兔喜生活', '杭州西湖区文一路店', '17:45', 0),
        new ParcelModel('6-2-2177', '中通快递', '菜鸟驿站', '杭州万泰凤华新建店', '16:20', 0),
        new ParcelModel('6-2-2178', '中通快递', '妈妈驿站', '杭州城西银泰店', '15:30', 0),
        new ParcelModel('6-2-2179', '中通快递', '菜鸟驿站', '杭州万泰凤华新建店', '14:15', 0),
        
        // 京东快递 (2件)
        new ParcelModel('JD8888888888', '京东快递', '京东自提点', '杭州西湖区文一路', '18:20', 0),
        new ParcelModel('JD8888888889', '京东快递', '京东自提点', '杭州西湖区文一路', '16:30', 0),
        
        // 圆通速递 (4件)
        new ParcelModel('6-3-1234', '圆通速递', '菜鸟驿站', '杭州万泰凤华新建店', '18:15', 0),
        new ParcelModel('6-3-1235', '圆通速递', '兔喜生活', '杭州西湖区文一路店', '17:20', 0),
        new ParcelModel('6-3-1236', '圆通速递', '菜鸟驿站', '杭州万泰凤华新建店', '16:45', 0),
        new ParcelModel('6-3-1237', '圆通速递', '妈妈驿站', '杭州城西银泰店', '15:50', 0),
        
        // 极兔速递 (3件)
        new ParcelModel('2-5-2418', '极兔速递', '菜鸟驿站', '杭州万泰凤华新建店', '18:05', 0),
        new ParcelModel('2-5-2419', '极兔速递', '兔喜生活', '杭州西湖区文一路店', '17:30', 0),
        new ParcelModel('2-5-2420', '极兔速递', '菜鸟驿站', '杭州万泰凤华新建店', '16:10', 0),
        
        // 韵达快递 (1件)
        new ParcelModel('7-1-9876', '韵达快递', '菜鸟驿站', '杭州万泰凤华新建店', '17:40', 0),
        
        // 申通快递 (1件)
        new ParcelModel('8-2-5432', '申通快递', '兔喜生活', '杭州西湖区文一路店', '16:50', 0),
        
        // 邮政快递 (1件)
        new ParcelModel('EMS123456789', '邮政快递', '邮政营业厅', '杭州文三路邮局', '15:20', 0),
      ];

      // 将 pickupTime（如 '18:30'）转换为时间戳并设置到 createTime
      testParcels.forEach(parcel => {
        parcel.createTime = convertTimeToTimestamp(parcel.pickupTime);
      });

      for (const parcel of testParcels) {
        await this.database.insertParcel(parcel);
      }
      
      console.info('✅ 测试数据加载完成：共 ' + testParcels.length + ' 条记录');
      console.info('📦 中通快递：5件，圆通速递：4件，极兔速递：3件');
      console.info('📦 顺丰速运：2件，京东快递：2件');
      console.info('📦 韵达快递：1件，申通快递：1件，邮政快递：1件');
  }

  // 加载包裹数据
  async loadParcels() {
    const status = this.currentTab === 0 ? Constants.STATUS_PENDING : Constants.STATUS_PICKED;
    this.parcelList = await this.database.queryParcelsByStatus(status);
    // 更新分组数据
    this.groupedData = this.getGroupedParcels();
  }


  // 切换标签页
  async onTabChange(index: number) {
    this.currentTab = index;
    this.isEditMode = false;
    this.selectedParcels.clear();
    this.companySortOrder = []; // 清空排序顺序，因为待取和已取的数据不同
    await this.loadParcels();
  }

  // 切换包裹状态
  async toggleParcelStatus(parcel: ParcelModel) {
    if (parcel.id) {
      const newStatus = parcel.status === Constants.STATUS_PENDING ?
        Constants.STATUS_PICKED : Constants.STATUS_PENDING;
      await this.database.updateParcelStatus(parcel.id, newStatus);
      
      // 添加友好提示
      if (newStatus === Constants.STATUS_PICKED) {
        promptAction.showToast({ 
          message: `${parcel.courierCompany} 已标记为已取，可在"已取"标签查看`, 
          duration: 2000 
        });
      } else {
        promptAction.showToast({ 
          message: `${parcel.courierCompany} 已恢复到待取列表`, 
          duration: 2000 
        });
      }
      
      await this.loadParcels();
    }
  }

  // 复制取件码
  async copyPickupCode(code: string) {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, code);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      promptAction.showToast({ message: '取件码已复制', duration: 2000 });
    } catch (error) {
      console.error('Copy failed:', JSON.stringify(error));
    }
  }

  // 删除选中的包裹
  async deleteSelectedParcels() {
    const ids = Array.from(this.selectedParcels);
    if (ids.length > 0) {
      await this.database.batchDeleteParcels(ids);
      this.selectedParcels.clear();
      this.isEditMode = false;
      await this.loadParcels();
      promptAction.showToast({ message: '删除成功', duration: 2000 });
    }
  }

  // 删除单个包裹（侧滑删除）
  async deleteSingleParcel(parcel: ParcelModel) {
    if (parcel.id) {
      await this.database.deleteParcel(parcel.id);
      await this.loadParcels();
      promptAction.showToast({ 
        message: `已删除 ${parcel.courierCompany} - ${parcel.pickupCode}`, 
        duration: 2000 
      });
    }
  }

  // 清空所有已取的包裹
  async clearAllPickedParcels() {
    if (this.parcelList.length === 0) {
      promptAction.showToast({ message: '没有可清空的记录', duration: 2000 });
      return;
    }

    // 显示确认对话框
    promptAction.showDialog({
      title: '确认清空',
      message: `确定要清空所有已取的记录吗？共 ${this.parcelList.length} 条记录将被删除。`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#FF0000' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        // 用户点击了确定
        const ids = this.parcelList.map(p => p.id).filter(id => id !== undefined) as number[];
        if (ids.length > 0) {
          await this.database.batchDeleteParcels(ids);
          await this.loadParcels();
          promptAction.showToast({ 
            message: `已清空 ${ids.length} 条记录`, 
            duration: 2000 
          });
        }
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
  }

  // 跳转到添加页面
  async navigateToAddPage() {
    await router.pushUrl({ url: 'pages/AddParcel' });
    // 数据刷新由 onPageShow() 生命周期处理
  }

  // 从剪贴板导入短信
  async importFromClipboard() {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = await systemPasteboard.getData();
      
      if (pasteData && pasteData.getPrimaryText()) {
        const clipboardText = pasteData.getPrimaryText();
        // 跳转到短信导入页面
        await router.pushUrl({
          url: 'pages/SmsImport',
          params: {
            smsContent: clipboardText
          }
        });
      } else {
        promptAction.showToast({
          message: '剪贴板为空',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('Read clipboard failed:', JSON.stringify(error));
      promptAction.showToast({
        message: '读取剪贴板失败',
        duration: 2000
      });
    }
  }

  // 获取快递公司图标颜色
  getCourierColor(company: string): string {
    return IconUtils.getCourierColor(company);
  }

  // 获取快递公司缩写
  getCourierAbbr(company: string): string {
    return IconUtils.getCourierAbbr(company);
  }

  // 获取排序后的包裹列表
  getSortedParcels(recomputeOrder: boolean = false): ParcelModel[] {
    if (this.selectedSortMode === '按时间') {
      // 按时间排序（最新的在前面）
      return [...this.parcelList].sort((a, b) => b.createTime - a.createTime);
    } else {
      // 按快递公司排序
      return this.sortParcelsByCompanyCount(this.parcelList, recomputeOrder);
    }
  }

  // 按日期分组
  getGroupedParcels(recomputeOrder: boolean = false): Map<string, ParcelModel[]> {
    const grouped = new Map<string, ParcelModel[]>();
    const sortedList = this.getSortedParcels(recomputeOrder);

    sortedList.forEach(parcel => {
      const date = new Date(parcel.createTime);
      const dateKey = `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

      if (!grouped.has(dateKey)) {
        grouped.set(dateKey, []);
      }
      grouped.get(dateKey)?.push(parcel);
    });

    return grouped;
  }

  // 按快递公司待取件数量排序包裹列表
  sortParcelsByCompanyCount(parcels: ParcelModel[], recomputeOrder: boolean = false): ParcelModel[] {
    // 1. 按快递公司分组
    const companyGroups = new Map<string, ParcelModel[]>();
    parcels.forEach(parcel => {
      const company = parcel.courierCompany;
      if (!companyGroups.has(company)) {
        companyGroups.set(company, []);
      }
      companyGroups.get(company)?.push(parcel);
    });

    // 2. 对每个快递公司的包裹按时间排序
    companyGroups.forEach((parcels, company) => {
      parcels.sort((a, b) => b.createTime - a.createTime);
    });

    // 3. 确定快递公司的顺序
    let sortedCompanies: string[] = [];
    
    if (recomputeOrder || this.companySortOrder.length === 0) {
      // 需要重新计算顺序：按包裹数量排序
      const companyCount = new Map<string, number>();
      parcels.forEach(parcel => {
        const company = parcel.courierCompany;
        companyCount.set(company, (companyCount.get(company) || 0) + 1);
      });

      sortedCompanies = Array.from(companyGroups.keys()).sort((a, b) => {
        const countA = companyCount.get(a) || 0;
        const countB = companyCount.get(b) || 0;

        // 数量多的排前面
        if (countA !== countB) {
          return countB - countA;
        }

        // 数量相同，按首个包裹的创建时间排序
        const parcelsA = companyGroups.get(a) || [];
        const parcelsB = companyGroups.get(b) || [];
        if (parcelsA.length > 0 && parcelsB.length > 0) {
          return parcelsB[0].createTime - parcelsA[0].createTime;
        }

        return 0;
      });

      // 保存顺序
      this.companySortOrder = sortedCompanies;
    } else {
      // 使用保存的顺序，但只包含当前存在的公司
      const currentCompanies = new Set(companyGroups.keys());
      sortedCompanies = this.companySortOrder.filter(company => currentCompanies.has(company));
      
      // 添加新出现的公司（如果有的话）
      currentCompanies.forEach(company => {
        if (!this.companySortOrder.includes(company)) {
          sortedCompanies.push(company);
        }
      });
    }

    // 4. 组合排序后的结果
    const sortedParcels: ParcelModel[] = [];
    sortedCompanies.forEach(company => {
      const companyParcels = companyGroups.get(company) || [];
      sortedParcels.push(...companyParcels);
    });

    return sortedParcels;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopBar()

      // 筛选区域
      if (this.currentTab === 0) {
        this.FilterBar()
      }

      // 列表区域
      this.ParcelList()

      // 底部 TabBar
      this.BottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }

  @Builder
  TopBar() {
    Row() {
      // 左侧菜单按钮
      Image($r('app.media.big_logo'))
        .width(24)
        .height(24)
        .margin({ left: 16 })

      // 标题
      Text(this.currentTab === 0 ?
        `待取包裹 (${this.parcelList.length})` :
        '取件记录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 16 })
        .layoutWeight(1)

      // 右侧功能按钮
      Row({ space: 16 }) {
        // 添加按钮
        Text('+')
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.navigateToAddPage();
          })

        // 扫码按钮
        Text('⊞')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .onClick(async () => {
            const context = getContext(this) as common.UIAbilityContext;
            await this.scanService.startScan(context);
            // 扫码后刷新数据
            await this.loadParcels();
          })

        // 导入按钮（待取页面显示）
        if (this.currentTab === 0) {
          Text('📋')
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.importFromClipboard();
            })
        }

        // 已取页面：清空和删除按钮
        if (this.currentTab === 1) {
          Text('清空')
            .fontSize(16)
            .fontColor($r('app.color.accent_blue'))
            .onClick(() => {
              this.clearAllPickedParcels();
            })
          
          Image($r('app.media.big_logo'))
            .width(24)
            .height(24)
            .onClick(() => {
              this.isEditMode = !this.isEditMode;
              if (!this.isEditMode) {
                this.selectedParcels.clear();
              }
            })
        }
      }
      .margin({ right: 16 })
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  FilterBar() {
    Row() {
      // 排序模式切换（两个TAB）
      Row({ space: 8 }) {
        // 按时间
        Text('按时间')
          .fontSize(14)
          .fontColor(this.selectedSortMode === '按时间' ?
            $r('app.color.filter_button_active_text') :
            $r('app.color.filter_button_text'))
          .backgroundColor(this.selectedSortMode === '按时间' ?
            $r('app.color.filter_button_active_bg') :
            Color.Transparent)
          .border({
            width: this.selectedSortMode === '按时间' ? 0 : 1.5,
            color: this.selectedSortMode === '按时间' ? 
              Color.Transparent : 
              $r('app.color.tab_border_color')
          })
          .borderRadius(8)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .onClick(() => {
            this.selectedSortMode = '按时间';
            this.groupedData = this.getGroupedParcels(false);
          })

        // 按快递公司
        Text('按快递公司')
          .fontSize(14)
          .fontColor(this.selectedSortMode === '按快递公司' ?
            $r('app.color.filter_button_active_text') :
            $r('app.color.filter_button_text'))
          .backgroundColor(this.selectedSortMode === '按快递公司' ?
            $r('app.color.filter_button_active_bg') :
            Color.Transparent)
          .border({
            width: this.selectedSortMode === '按快递公司' ? 0 : 1.5,
            color: this.selectedSortMode === '按快递公司' ? 
              Color.Transparent : 
              $r('app.color.tab_border_color')
          })
          .borderRadius(8)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .onClick(() => {
            this.selectedSortMode = '按快递公司';
            this.groupedData = this.getGroupedParcels(true); // 切换到"按快递公司"时重新排序
          })
      }
      .padding({ left: 16 })
      .layoutWeight(1)

      // 勾选框（右侧）
      Checkbox()
        .width(24)
        .height(24)
        .margin({ right: 16 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  ParcelList() {
    if (this.parcelList.length === 0) {
      // 空状态提示
      this.EmptyState()
    } else {
      List({ space: 0 }) {
        ForEach(Array.from(this.groupedData.keys()), (date: string) => {
          ListItemGroup({ header: this.DateHeader(date, this.groupedData.get(date)?.length || 0) }) {
            ForEach(this.groupedData.get(date) || [], (parcel: ParcelModel) => {
              ListItem() {
                this.ParcelCard(parcel)
              }
              .swipeAction({ end: this.DeleteButton(parcel) })
            }, (parcel: ParcelModel) => parcel.id?.toString() || '')
          }
        }, (date: string) => date)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_color'))
      .padding({ left: 16, right: 16 })
    }
  }

  @Builder
  EmptyState() {
    Column({ space: 16 }) {
      // 空状态图标
      Text('📦')
        .fontSize(80)
        .margin({ top: 100 })

      // 提示文字
      Text(this.getEmptyStateText())
        .fontSize(16)
        .fontColor($r('app.color.secondary_text'))
        .textAlign(TextAlign.Center)

      // 操作建议（仅待取页面显示）
      if (this.currentTab === 0) {
        Column({ space: 12 }) {
          Text('点击右上角 + 号添加取件码')
            .fontSize(14)
            .fontColor($r('app.color.accent_blue'))

          Text('或点击扫码图标扫描快递单')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
        }
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.background_color'))
  }

  // 获取空状态提示文字
  getEmptyStateText(): string {
    return this.currentTab === 0 ?
      '暂无待取的快递包裹' :
      '暂无已取的快递记录';
  }

  @Builder
  DateHeader(date: string, count: number) {
    Row() {
      Text(date)
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))

      Blank()

      Text(`${count}条记录`)
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
    }
    .width('100%')
    .padding({ top: 12, bottom: 8 })
  }

  @Builder
  DeleteButton(parcel: ParcelModel) {
    Row() {
      Text('删除')
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width(80)
    .height('100%')
    .backgroundColor(Color.Red)
    .justifyContent(FlexAlign.Center)
    .borderRadius(12)
    .margin({ top: 6, bottom: 6 })
    .onClick(() => {
      this.deleteSingleParcel(parcel);
    })
  }

  @Builder
  ParcelCard(parcel: ParcelModel) {
    Row() {
      // 左侧：快递公司图标（正方形带圆角）
      this.CourierIconView(parcel.courierCompany, parcel.status)

      // 中间：信息区域
      Column({ space: 4 }) {
        // 快递公司名称（标题）
        Text(parcel.courierCompany)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(parcel.status === Constants.STATUS_PICKED ?
            $r('app.color.secondary_text') :
            $r('app.color.primary_text'))

        // 驿站名称和地址
        Text(`${parcel.stationName} · ${parcel.address}`)
          .fontSize(13)
          .fontColor($r('app.color.secondary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(parcel.status === Constants.STATUS_PICKED ? 0.6 : 1)

        // 取件码（大号字体，支持长单号自适应）
        Text(parcel.pickupCode)
          .fontSize(24)
          .minFontSize(18)
          .maxLines(1)
          .fontWeight(FontWeight.Bold)
          .fontColor(parcel.status === Constants.STATUS_PICKED ?
            $r('app.color.secondary_text') :
            $r('app.color.primary_text'))
          .decoration({
            type: parcel.status === Constants.STATUS_PICKED ?
              TextDecorationType.LineThrough :
              TextDecorationType.None
          })
          .letterSpacing(1)
          .margin({ top: 4 })
          .textOverflow({ overflow: TextOverflow.Clip })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.copyPickupCode(parcel.pickupCode);
              })
          )
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：时间和状态
      Column({ space: 8 }) {
        Text(`${parcel.pickupTime} ${this.currentTab === 0 ? '' : '取件'}`)
          .fontSize(13)
          .fontColor($r('app.color.primary_text'))
          .opacity(parcel.status === Constants.STATUS_PICKED ? 0.6 : 0.85)

        // 勾选框
        if (this.currentTab === 0) {
          // 待取：圆形框
          Circle({ width: 24, height: 24 })
            .fill(Color.Transparent)
            .stroke($r('app.color.divider_color'))
            .strokeWidth(2)
            .onClick(() => {
              this.toggleParcelStatus(parcel);
            })
        } else {
          // 已取：蓝色勾选
          Stack() {
            Circle({ width: 24, height: 24 })
              .fill($r('app.color.accent_blue'))
            Text('✓')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .onClick(() => {
            this.toggleParcelStatus(parcel);
          })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .padding(16)
    .margin({ top: 6, bottom: 6 })
    .shadow({ 
      radius: 8, 
      color: '#15000000', 
      offsetX: 0, 
      offsetY: 2 
    })
    .border({
      width: 1,
      color: parcel.status === Constants.STATUS_PICKED ? 
        $r('app.color.divider_color') : 
        Color.Transparent
    })
  }

  // 快递公司图标组件（智能显示真实图标或文字图标）
  @Builder
  CourierIconView(company: string, status: number) {
    Stack() {
      // 底层：彩色背景 + 文字图标（备用方案）
      Stack() {
        Text(this.getCourierAbbr(company))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: 2, color: '#40000000', offsetX: 0, offsetY: 1 })
      }
      .width(48)
      .height(48)
      .backgroundColor(this.getCourierColor(company))
      .borderRadius(8)
      
      // 顶层：真实图标（如果存在）
      Image(this.getCourierIconResource(company))
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
    }
    .width(48)
    .height(48)
    .opacity(status === Constants.STATUS_PICKED ? 0.5 : 1)
    .margin({ right: 12 })
  }

  // 获取快递公司图标资源
  getCourierIconResource(company: string): Resource {
    const lowerCompany = company.toLowerCase();

    // 匹配 AppScope/resources/base/media 目录下的真实图标
    if (lowerCompany.includes('顺丰') || lowerCompany.includes('sf')) {
      return $r('app.media.shunfeng'); // shunfeng.png
    } else if (lowerCompany.includes('中通') || lowerCompany.includes('zto')) {
      return $r('app.media.zhongtong'); // zhongtong.png
    } else if (lowerCompany.includes('申通') || lowerCompany.includes('sto')) {
      return $r('app.media.shentong'); // shentong.png
    } else if (lowerCompany.includes('韵达')) {
      return $r('app.media.yunda'); // yunda.png
    } else if (lowerCompany.includes('极兔') || lowerCompany.includes('jt') || lowerCompany.includes('j&t')) {
      return $r('app.media.jtexpress'); // jtexpress.png
    } else if (lowerCompany.includes('邮政') || lowerCompany.includes('ems')) {
      return $r('app.media.youzhengguonei'); // youzhengguonei.png
    } else if (lowerCompany.includes('圆通') || lowerCompany.includes('yto')) {
      return $r('app.media.yuantong'); // yuantong.png
    } else if (lowerCompany.includes('京东') || lowerCompany.includes('jd')) {
      return $r('app.media.jd'); // jd.png
    } else if (lowerCompany.includes('百世')) {
      return $r('app.media.baishiwuliu'); // baishiwuliu.png
    } else if (lowerCompany.includes('德邦')) {
      return $r('app.media.debangwuliu'); // debangwuliu.png
    } else if (lowerCompany.includes('安能')) {
      return $r('app.media.annengwuliu'); // annengwuliu.png
    } else if (lowerCompany.includes('菜鸟')) {
      return $r('app.media.cainiao');
    }
    return $r('app.media.big_logo'); // 默认图标
  }

  @Builder
  BottomTabBar() {
    Row() {
      // 待取标签
      Column({ space: 4 }) {
        Text(this.currentTab === 0 ? '📦' : '📦')
          .fontSize(24)
        Text('待取')
          .fontSize(14)
          .fontColor(this.currentTab === 0 ?
            $r('app.color.primary_text') :
            $r('app.color.secondary_text'))
          .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
      }
      .width('50%')
      .padding(12)
      .onClick(() => {
        this.onTabChange(0);
      })

      // 已取标签
      Column({ space: 4 }) {
        Stack() {
          Circle({ width: 24, height: 24 })
            .fill(this.currentTab === 1 ? $r('app.color.accent_blue') : '#A0A0A0')
          Text('✓')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        Text('已取')
          .fontSize(14)
          .fontColor(this.currentTab === 1 ?
            $r('app.color.primary_text') :
            '#666666')
          .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
      }
      .width('50%')
      .padding(12)
      .onClick(() => {
        this.onTabChange(1);
      })
    }
    .width('100%')
    .height(64)
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: $r('app.color.divider_color') })
  }
}
