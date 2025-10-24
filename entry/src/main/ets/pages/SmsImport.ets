import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { SmsService } from '../service/SmsService';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct SmsImport {
  @State smsContent: string = '';
  @State parsedParcel: ParcelModel | null = null;
  @State parseSuccess: boolean = false;
  @State pickupCode: string = '';
  @State courierCompany: string = '';
  @State stationName: string = '';
  @State address: string = '';
  
  private database: ParcelDatabase = ParcelDatabase.getInstance();
  private smsService: SmsService = SmsService.getInstance();

  async aboutToAppear() {
    // 初始化数据库
    const context = getContext(this) as common.UIAbilityContext;
    await this.database.initDB(context);
    
    // 优先从 AppStorage 获取短信内容（分享进入）
    const pendingSmsContent = AppStorage.get<string>('pendingSmsContent');
    if (pendingSmsContent) {
      this.smsContent = pendingSmsContent;
      AppStorage.delete('pendingSmsContent'); // 清空
      await this.parseSms();
      return;
    }
    
    // 其次从路由参数获取（手动导入）
    const params = router.getParams() as Record<string, string>;
    if (params && params.smsContent) {
      this.smsContent = params.smsContent;
      await this.parseSms();
    }
  }

  // 解析短信内容
  async parseSms() {
    const parcel = this.smsService.parseSmsContent(this.smsContent);
    if (parcel) {
      this.parsedParcel = parcel;
      this.parseSuccess = true;
      this.pickupCode = parcel.pickupCode;
      this.courierCompany = parcel.courierCompany;
      this.stationName = parcel.stationName;
      this.address = parcel.address;
    } else {
      this.parseSuccess = false;
      promptAction.showToast({
        message: '未识别到取件码信息，请检查短信内容',
        duration: 2000
      });
    }
  }

  // 保存取件码
  async saveParcel() {
    if (!this.parsedParcel) {
      return;
    }

    // 更新修改后的值
    this.parsedParcel.pickupCode = this.pickupCode;
    this.parsedParcel.courierCompany = this.courierCompany;
    this.parsedParcel.stationName = this.stationName;
    this.parsedParcel.address = this.address;

    const result = await this.database.insertParcel(this.parsedParcel);
    if (result > 0) {
      promptAction.showToast({
        message: '取件码已保存',
        duration: 2000
      });
      // 返回首页
      router.back();
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    }
  }

  // 取消并返回
  goBack() {
    router.back();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.goBack();
          })
          .margin({ left: 16 })

        Text('短信导入')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)

      // 主内容区
      Column({ space: 20 }) {
        if (this.parseSuccess) {
          // 成功解析
          Column({ space: 16 }) {
            // 成功提示
            Row() {
              Text('✓')
                .fontSize(48)
                .fontColor('#07C160')
                .fontWeight(FontWeight.Bold)
            }
            .justifyContent(FlexAlign.Center)
            .margin({ top: 20 })

            Text('识别成功！')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_text'))

            Text('请确认以下信息')
              .fontSize(14)
              .fontColor($r('app.color.secondary_text'))

            // 信息编辑区
            Column({ space: 12 }) {
              // 取件码
              Column({ space: 4 }) {
                Text('取件码')
                  .fontSize(14)
                  .fontColor($r('app.color.secondary_text'))
                TextInput({ text: this.pickupCode })
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .backgroundColor($r('app.color.background_color'))
                  .onChange((value: string) => {
                    this.pickupCode = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)

              // 快递公司
              Column({ space: 4 }) {
                Text('快递公司')
                  .fontSize(14)
                  .fontColor($r('app.color.secondary_text'))
                TextInput({ text: this.courierCompany })
                  .fontSize(16)
                  .backgroundColor($r('app.color.background_color'))
                  .onChange((value: string) => {
                    this.courierCompany = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)

              // 驿站名称
              Column({ space: 4 }) {
                Text('驿站名称')
                  .fontSize(14)
                  .fontColor($r('app.color.secondary_text'))
                TextInput({ text: this.stationName })
                  .fontSize(16)
                  .backgroundColor($r('app.color.background_color'))
                  .onChange((value: string) => {
                    this.stationName = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)

              // 地址
              Column({ space: 4 }) {
                Text('地址')
                  .fontSize(14)
                  .fontColor($r('app.color.secondary_text'))
                TextInput({ text: this.address })
                  .fontSize(16)
                  .backgroundColor($r('app.color.background_color'))
                  .onChange((value: string) => {
                    this.address = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 操作按钮
            Row({ space: 12 }) {
              Button('取消')
                .fontSize(16)
                .fontColor($r('app.color.primary_text'))
                .backgroundColor($r('app.color.background_color'))
                .layoutWeight(1)
                .onClick(() => {
                  this.goBack();
                })

              Button('保存')
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.accent_blue'))
                .layoutWeight(1)
                .onClick(() => {
                  this.saveParcel();
                })
            }
            .width('100%')
            .margin({ top: 20 })
          }
        } else {
          // 解析失败
          Column({ space: 16 }) {
            Text('✗')
              .fontSize(48)
              .fontColor('#FA5151')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20 })

            Text('未识别到取件码')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_text'))

            Text('短信内容示例：')
              .fontSize(14)
              .fontColor($r('app.color.secondary_text'))
              .margin({ top: 12 })

            Column({ space: 8 }) {
              Text('【菜鸟驿站】您的快递已到达')
                .fontSize(14)
                .fontColor($r('app.color.secondary_text'))
              Text('取件码：2-5-2418')
                .fontSize(14)
                .fontColor($r('app.color.secondary_text'))
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.background_color'))
            .borderRadius(8)

            Button('返回')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.accent_blue'))
              .width('100%')
              .margin({ top: 20 })
              .onClick(() => {
                this.goBack();
              })
          }
        }
      }
      .width('100%')
      .padding(20)
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_color'))
    }
    .width('100%')
    .height('100%')
  }
}

