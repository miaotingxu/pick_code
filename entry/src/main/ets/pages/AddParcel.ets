import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct AddParcel {
  @State pickupCode: string = '';
  @State courierCompany: string = '';
  @State stationName: string = '';
  @State address: string = '';
  @State showCompanyPicker: boolean = false;
  private database: ParcelDatabase = ParcelDatabase.getInstance();

  // 保存包裹信息
  async saveParcel() {
    // 验证必填项
    if (!this.pickupCode || !this.courierCompany || !this.stationName) {
      promptAction.showToast({ message: '请填写完整信息', duration: 2000 });
      return;
    }

    // 验证取件码格式
    const codePattern = /^\d+-\d+-\d+$/;
    if (!codePattern.test(this.pickupCode.trim())) {
      promptAction.showToast({ message: '取件码格式不正确（示例：2-5-2418）', duration: 2000 });
      return;
    }

    // 创建包裹对象
    const now = new Date();
    const pickupTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    
    const parcel = new ParcelModel(
      this.pickupCode.trim(),
      this.courierCompany,
      this.stationName.trim(),
      this.address.trim(),
      pickupTime,
      Constants.STATUS_PENDING
    );

    // 保存到数据库
    const result = await this.database.insertParcel(parcel);
    
    if (result > 0) {
      promptAction.showToast({ message: '添加成功', duration: 2000 });
      router.back();
    } else {
      promptAction.showToast({ message: '添加失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .onClick(() => {
            router.back();
          })

        Text('添加取件码')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('保存')
          .fontSize(16)
          .fontColor($r('app.color.accent_blue'))
          .onClick(() => {
            this.saveParcel();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: $r('app.color.divider_color') })

      // 表单区域
      Column({ space: 0 }) {
        // 快递公司
        this.FormItem('快递公司', this.courierCompany || '请选择快递公司', true, () => {
          this.showCompanyPicker = true;
        })

        // 驿站名称
        this.FormItem('驿站名称', this.stationName, false, undefined, (value: string) => {
          this.stationName = value;
        })

        // 取件码
        this.FormItem('取件码', this.pickupCode, false, undefined, (value: string) => {
          this.pickupCode = value;
        })

        // 地址
        this.FormItem('地址', this.address, false, undefined, (value: string) => {
          this.address = value;
        })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
    .bindSheet($$this.showCompanyPicker, this.CompanyPickerSheet(), {
      height: 400,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showCompanyPicker = false;
      }
    })
  }

  @Builder
  FormItem(
    label: string,
    value: string,
    isSelector: boolean,
    onTap?: () => void,
    onChange?: (value: string) => void
  ) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .width(100)

      if (isSelector) {
        Row() {
          Text(value)
            .fontSize(16)
            .fontColor(value.includes('请选择') ? 
              $r('app.color.secondary_text') : 
              $r('app.color.primary_text'))
            .layoutWeight(1)
          
          Text('›')
            .fontSize(20)
            .fontColor($r('app.color.secondary_text'))
        }
        .layoutWeight(1)
        .onClick(() => {
          onTap?.();
        })
      } else {
        TextInput({ placeholder: `请输入${label}`, text: value })
          .fontSize(16)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            onChange?.(value);
          })
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: $r('app.color.divider_color') })
  }

  @Builder
  CompanyPickerSheet() {
    Column() {
      Text('选择快递公司')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(16)

      List() {
        ForEach(Constants.COURIER_COMPANIES, (company: ESObject) => {
          ListItem() {
            Row() {
              Text(company.name)
                .fontSize(16)
                .fontColor($r('app.color.primary_text'))
                .layoutWeight(1)
              
              if (this.courierCompany === company.name) {
                Text('✓')
                  .fontSize(20)
                  .fontColor($r('app.color.accent_blue'))
              }
            }
            .width('100%')
            .padding(16)
            .onClick(() => {
              this.courierCompany = company.name;
              this.showCompanyPicker = false;
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}

