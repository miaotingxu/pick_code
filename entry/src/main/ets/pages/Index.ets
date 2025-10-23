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
  @State selectedFilter: string = '按时间';
  @State isEditMode: boolean = false;
  @State selectedParcels: Set<number> = new Set();
  @State groupedData: Map<string, ParcelModel[]> = new Map();
  @State sortedFilterTags: string[] = ['按时间']; // 动态排序的筛选标签
  private database: ParcelDatabase = ParcelDatabase.getInstance();
  private scanService: ScanService = ScanService.getInstance();

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
    if (existingData.length === 0) {
      // 添加一些测试数据
      const testParcels = [
        new ParcelModel('2-5-2418', '极兔速递', '菜鸟驿站', '杭州万泰凤华新建店', '17:45', 0),
        new ParcelModel('6-2-2175', '中通快递', '菜鸟驿站', '杭州万泰凤华新建店', '17:37', 0),
        new ParcelModel('6-2-2173', '圆通速递', '菜鸟驿站', '杭州万泰凤华新建店', '17:37', 0),
        new ParcelModel('2-5-2498', '京东快递', '菜鸟驿站', '杭州万泰凤华新建店', '17:37', 0),
      ];

      for (const parcel of testParcels) {
        await this.database.insertParcel(parcel);
      }
    }
  }

  // 加载包裹数据
  async loadParcels() {
    const status = this.currentTab === 0 ? Constants.STATUS_PENDING : Constants.STATUS_PICKED;
    this.parcelList = await this.database.queryParcelsByStatus(status);
    // 更新筛选标签排序（仅在待取页面）
    if (this.currentTab === 0) {
      this.updateFilterTagsOrder();
    }
    // 更新分组数据
    this.groupedData = this.getGroupedParcels();
  }

  // 动态更新筛选标签排序
  updateFilterTagsOrder() {
    // 统计每个快递公司的待取件数量
    const companyCount = new Map<string, number>();

    // 遍历所有待取包裹，统计各快递公司数量
    this.parcelList.forEach(parcel => {
      const company = parcel.courierCompany;

      // 匹配快递公司与筛选标签的对应关系
      Constants.FILTER_TAGS.forEach(tag => {
        if (tag === '按时间') {
          return;
        }

        // 判断包裹是否属于该快递公司
        let isMatch = false;

        if (tag === '其他') {
          // "其他"匹配所有非主流快递
          let isMainCourier = false;
          for (const mainCourier of Constants.MAIN_COURIERS) {
            if (company.includes(mainCourier)) {
              isMainCourier = true;
              break;
            }
          }
          isMatch = !isMainCourier;
        } else if (tag === '顺丰' && company.includes('顺丰')) {
          isMatch = true;
        } else if (tag === '中通' && company.includes('中通')) {
          isMatch = true;
        } else if (tag === '申通' && company.includes('申通')) {
          isMatch = true;
        } else if (tag === '韵达' && company.includes('韵达')) {
          isMatch = true;
        } else if (tag === '极兔' && company.includes('极兔')) {
          isMatch = true;
        } else if (tag === '邮政' && (company.includes('邮政') || company.includes('EMS'))) {
          isMatch = true;
        } else if (tag === '圆通' && company.includes('圆通')) {
          isMatch = true;
        } else if (tag === '京东' && company.includes('京东')) {
          isMatch = true;
        } else if (tag === '百世' && company.includes('百世')) {
          isMatch = true;
        }

        if (isMatch) {
          companyCount.set(tag, (companyCount.get(tag) || 0) + 1);
        }
      });
    });

    // 对快递公司标签排序（按待取件数量降序）
    // "其他"始终放在最后
    const sortedCompanies = Constants.FILTER_TAGS
      .filter(tag => tag !== '按时间' && tag !== '其他')
      .sort((a, b) => {
        const countA = companyCount.get(a) || 0;
        const countB = companyCount.get(b) || 0;

        // 如果数量不同，数量多的排前面
        if (countA !== countB) {
          return countB - countA;
        }

        // 如果数量相同，保持原有顺序
        return Constants.FILTER_TAGS.indexOf(a) - Constants.FILTER_TAGS.indexOf(b);
      });

    // 组合结果："按时间"在第一位，"其他"在最后
    const otherCount = companyCount.get('其他') || 0;
    if (otherCount > 0) {
      this.sortedFilterTags = ['按时间', ...sortedCompanies, '其他'];
    } else {
      this.sortedFilterTags = ['按时间', ...sortedCompanies];
    }
  }

  // 切换标签页
  async onTabChange(index: number) {
    this.currentTab = index;
    this.isEditMode = false;
    this.selectedParcels.clear();
    await this.loadParcels();
  }

  // 切换包裹状态
  async toggleParcelStatus(parcel: ParcelModel) {
    if (parcel.id) {
      const newStatus = parcel.status === Constants.STATUS_PENDING ?
        Constants.STATUS_PICKED : Constants.STATUS_PENDING;
      await this.database.updateParcelStatus(parcel.id, newStatus);
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

  // 跳转到添加页面
  async navigateToAddPage() {
    await router.pushUrl({ url: 'pages/AddParcel' });
    // 数据刷新由 onPageShow() 生命周期处理
  }

  // 获取快递公司图标颜色
  getCourierColor(company: string): string {
    return IconUtils.getCourierColor(company);
  }

  // 获取快递公司缩写
  getCourierAbbr(company: string): string {
    return IconUtils.getCourierAbbr(company);
  }

  // 应用筛选
  getFilteredParcels(): ParcelModel[] {
    if (this.selectedFilter === '按时间') {
      return this.parcelList;
    }

    // 按快递公司筛选
    return this.parcelList.filter(parcel => {
      const company = parcel.courierCompany;

      // "其他"筛选：包含所有非主流快递公司
      if (this.selectedFilter === '其他') {
        // 检查是否属于主流快递
        let isMainCourier = false;
        for (const mainCourier of Constants.MAIN_COURIERS) {
          if (company.includes(mainCourier)) {
            isMainCourier = true;
            break;
          }
        }
        // 返回非主流快递（德邦、天天、宅急送、菜鸟、妈妈、兔喜等）
        return !isMainCourier;
      }

      // 根据筛选标签匹配快递公司
      if (this.selectedFilter === '顺丰') {
        return company.includes('顺丰');
      } else if (this.selectedFilter === '中通') {
        return company.includes('中通');
      } else if (this.selectedFilter === '申通') {
        return company.includes('申通');
      } else if (this.selectedFilter === '韵达') {
        return company.includes('韵达');
      } else if (this.selectedFilter === '极兔') {
        return company.includes('极兔');
      } else if (this.selectedFilter === '邮政') {
        return company.includes('邮政') || company.includes('EMS');
      } else if (this.selectedFilter === '圆通') {
        return company.includes('圆通');
      } else if (this.selectedFilter === '京东') {
        return company.includes('京东');
      } else if (this.selectedFilter === '百世') {
        return company.includes('百世');
      }

      return true;
    });
  }

  // 按日期分组
  getGroupedParcels(): Map<string, ParcelModel[]> {
    const grouped = new Map<string, ParcelModel[]>();
    let filteredList = this.getFilteredParcels();

    // 如果是"按时间"筛选，则按快递公司数量排序
    if (this.selectedFilter === '按时间') {
      filteredList = this.sortParcelsByCompanyCount(filteredList);
    }

    filteredList.forEach(parcel => {
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
  sortParcelsByCompanyCount(parcels: ParcelModel[]): ParcelModel[] {
    // 1. 统计每个快递公司的包裹数量
    const companyCount = new Map<string, number>();
    parcels.forEach(parcel => {
      const company = parcel.courierCompany;
      companyCount.set(company, (companyCount.get(company) || 0) + 1);
    });

    // 2. 按快递公司分组
    const companyGroups = new Map<string, ParcelModel[]>();
    parcels.forEach(parcel => {
      const company = parcel.courierCompany;
      if (!companyGroups.has(company)) {
        companyGroups.set(company, []);
      }
      companyGroups.get(company)?.push(parcel);
    });

    // 3. 对每个快递公司的包裹按时间排序
    companyGroups.forEach((parcels, company) => {
      parcels.sort((a, b) => b.createTime - a.createTime);
    });

    // 4. 按快递公司的包裹数量排序
    const sortedCompanies = Array.from(companyGroups.keys()).sort((a, b) => {
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

    // 5. 组合排序后的结果
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
      Image($r('app.media.startIcon'))
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

        // 删除按钮（已取页面显示）
        if (this.currentTab === 1) {
          Image($r('app.media.startIcon'))
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
      // 筛选按钮（左侧）- 使用 Scroll 支持横向滚动，按待取件数量动态排序
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.sortedFilterTags, (tag: string) => {
            Text(tag)
              .fontSize(14)
              .fontColor(this.selectedFilter === tag ?
                $r('app.color.filter_button_active_text') :
                $r('app.color.filter_button_text'))
              .backgroundColor(this.selectedFilter === tag ?
                $r('app.color.filter_button_active_bg') :
                Color.Transparent)
              .border({
                width: this.selectedFilter === tag ? 0 : 1.5,
                color: this.selectedFilter === tag ? 
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
                this.selectedFilter = tag;
                // 更新分组数据以应用筛选
                this.groupedData = this.getGroupedParcels();
              })
          })
        }
        .padding({ right: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      // 勾选框（右侧）
      Checkbox()
        .width(24)
        .height(24)
        .margin({ right: 16 })
    }
    .width('100%')
    .padding({ left: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  ParcelList() {
    if (this.parcelList.length === 0 || this.getFilteredParcels().length === 0) {
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
            }, (parcel: ParcelModel) => parcel.id?.toString() || '')
          }
        })
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

      // 操作建议
      if (this.selectedFilter !== '按时间') {
        Text('点击"按时间"查看所有包裹')
          .fontSize(14)
          .fontColor($r('app.color.accent_blue'))
          .margin({ top: 8 })
          .onClick(() => {
            this.selectedFilter = '按时间';
            this.groupedData = this.getGroupedParcels();
          })
      } else if (this.currentTab === 0) {
        // 待取页面且无数据，提示添加
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
    if (this.selectedFilter === '按时间') {
      return this.currentTab === 0 ?
        '暂无待取的快递包裹' :
        '暂无已取的快递记录';
    } else if (this.selectedFilter === '其他') {
      return '暂无其他快递公司的包裹';
    } else {
      return `暂无${this.selectedFilter}快递的包裹`;
    }
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

        // 取件码（大号字体）
        Text(parcel.pickupCode)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(parcel.status === Constants.STATUS_PICKED ?
            $r('app.color.secondary_text') :
            $r('app.color.primary_text'))
          .decoration({
            type: parcel.status === Constants.STATUS_PICKED ?
              TextDecorationType.LineThrough :
              TextDecorationType.None
          })
          .letterSpacing(2)
          .margin({ top: 4 })
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
    return $r('app.media.startIcon'); // 默认图标
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
        Text(this.currentTab === 1 ? '✓' : '✓')
          .fontSize(24)
        Text('已取')
          .fontSize(14)
          .fontColor(this.currentTab === 1 ?
            $r('app.color.primary_text') :
            $r('app.color.secondary_text'))
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
