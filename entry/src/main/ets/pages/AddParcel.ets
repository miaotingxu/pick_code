import { ParcelModel, CourierCompanyInfo } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct AddParcel {
  @State pickupCode: string = '';
  @State courierCompany: string = '';
  @State stationName: string = '';
  @State address: string = '';
  @State showCompanyPicker: boolean = false;
  @State showCustomCompanyInput: boolean = false;
  @State customCompanyName: string = '';
  @State courierHistory: string[] = [];
  private database: ParcelDatabase = ParcelDatabase.getInstance();
  private companyDialogController: CustomDialogController = new CustomDialogController({
    builder: CompanyPickerDialog({
      selectedCompany: this.courierCompany,
      onConfirm: (company: string) => {
        this.courierCompany = company;
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 },
    customStyle: true,
    autoCancel: true
  });

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await this.database.initDB(context);
    await this.loadHistory();
    
    // 调试：验证快递公司数据
    console.info('快递公司总数:', Constants.COURIER_COMPANIES.length);
    if (Constants.COURIER_COMPANIES.length > 0) {
      console.info('第一个快递公司:', Constants.COURIER_COMPANIES[0].name);
    }
  }

  // 加载历史记录
  async loadHistory() {
    this.courierHistory = await this.database.queryCourierCompanies();
  }

  // 保存包裹信息
  async saveParcel() {
    // 验证必填项
    if (!this.pickupCode || !this.courierCompany || !this.stationName) {
      promptAction.showToast({ message: '请填写完整信息', duration: 2000 });
      return;
    }

    // 创建包裹对象
    const now = new Date();
    const pickupTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    
    const parcel = new ParcelModel(
      this.pickupCode.trim(),
      this.courierCompany.trim(),
      this.stationName.trim(),
      this.address.trim(),
      pickupTime,
      Constants.STATUS_PENDING
    );

    // 保存到数据库
    const result = await this.database.insertParcel(parcel);
    
    if (result > 0) {
      // 保存快递公司和驿站名称到历史记录
      await this.database.addOrUpdateCourierCompany(this.courierCompany.trim());
      await this.database.addOrUpdateStationName(this.stationName.trim());
      
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
          this.companyDialogController.open();
        })

        // 驿站名称（手动输入，如：菜鸟驿站、兔喜生活等）
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
    .bindSheet($$this.showCustomCompanyInput, this.CustomCompanyInputSheet(), {
      height: 280,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showCustomCompanyInput = false;
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
        TextInput({ 
          placeholder: label === '驿站名称' ? '如：菜鸟驿站、兔喜生活、妈妈驿站等' : `请输入${label}`, 
          text: value 
        })
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
  CustomCompanyInputSheet() {
    Column() {
      Text('自定义快递公司')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 20 })

      Column() {
        TextInput({ placeholder: '请输入快递公司名称', text: this.customCompanyName })
          .fontSize(16)
          .padding(12)
          .onChange((value: string) => {
            this.customCompanyName = value;
          })
      }
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 24 })

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .backgroundColor($r('app.color.background_color'))
          .layoutWeight(1)
          .onClick(() => {
            this.showCustomCompanyInput = false;
            this.customCompanyName = '';
          })

        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.accent_blue'))
          .layoutWeight(1)
          .onClick(() => {
            if (this.customCompanyName.trim()) {
              this.courierCompany = this.customCompanyName.trim();
              this.showCustomCompanyInput = false;
              this.customCompanyName = '';
            } else {
              promptAction.showToast({ message: '请输入快递公司名称', duration: 2000 });
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }
}

@CustomDialog
struct CompanyPickerDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: CompanyPickerDialog()
  });
  @State selectedCompany: string = '';
  onConfirm: (company: string) => void = () => {};

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .padding(16)
          .onClick(() => {
            this.controller.close();
          })
        
        Text('选择快递公司')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('     ')
          .fontSize(16)
          .padding(16)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 滚动列表
      Scroll() {
        Column() {
          this.CompanyItem('顺丰速运')
          this.CompanyItem('中通快递')
          this.CompanyItem('申通快递')
          this.CompanyItem('韵达快递')
          this.CompanyItem('极兔速递')
          this.CompanyItem('邮政快递')
          this.CompanyItem('圆通速递')
          this.CompanyItem('京东快递')
          this.CompanyItem('百世快递')
          this.CompanyItem('德邦快递')
          this.CompanyItem('安能物流')
          this.CompanyItem('天天快递')
          this.CompanyItem('宅急送')
          this.CompanyItem('菜鸟驿站')
          this.CompanyItem('妈妈驿站')
          this.CompanyItem('兔喜生活')
        }
      }
      .width('100%')
      .height('500vp')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
  
  @Builder
  CompanyItem(name: string) {
    Row() {
      Text(name)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .layoutWeight(1)
      
      if (this.selectedCompany === name) {
        Text('✓')
          .fontSize(20)
          .fontColor($r('app.color.accent_blue'))
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(() => {
      this.selectedCompany = name;
      this.onConfirm(name);
      this.controller.close();
    })
  }
}

