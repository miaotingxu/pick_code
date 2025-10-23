import { ParcelModel } from '../model/ParcelModel';
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
  @State showStationPicker: boolean = false;
  @State showCustomCompanyInput: boolean = false;
  @State showCustomStationInput: boolean = false;
  @State customCompanyName: string = '';
  @State customStationName: string = '';
  @State courierHistory: string[] = [];
  @State stationHistory: string[] = [];
  private database: ParcelDatabase = ParcelDatabase.getInstance();

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await this.database.initDB(context);
    await this.loadHistory();
  }

  // 加载历史记录
  async loadHistory() {
    this.courierHistory = await this.database.queryCourierCompanies();
    this.stationHistory = await this.database.queryStationNames();
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
          this.showCompanyPicker = true;
        })

        // 驿站名称
        this.FormItem('驿站名称', this.stationName || '请选择驿站名称', true, () => {
          this.showStationPicker = true;
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
      height: 500,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showCompanyPicker = false;
      }
    })
    .bindSheet($$this.showStationPicker, this.StationPickerSheet(), {
      height: 500,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showStationPicker = false;
      }
    })
    .bindSheet($$this.showCustomCompanyInput, this.CustomCompanyInputSheet(), {
      height: 280,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showCustomCompanyInput = false;
      }
    })
    .bindSheet($$this.showCustomStationInput, this.CustomStationInputSheet(), {
      height: 280,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.showCustomStationInput = false;
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
        // 历史记录
        if (this.courierHistory.length > 0) {
          ListItem() {
            Text('历史记录')
              .fontSize(14)
              .fontColor($r('app.color.secondary_text'))
              .padding({ left: 16, top: 12, bottom: 8 })
          }

          ForEach(this.courierHistory, (name: string) => {
            ListItem() {
              Row() {
                Column() {
                  Text(name)
                    .fontSize(16)
                    .fontColor($r('app.color.primary_text'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                
                if (this.courierCompany === name) {
                  Text('✓')
                    .fontSize(20)
                    .fontColor($r('app.color.accent_blue'))
                }
              }
              .width('100%')
              .padding(16)
              .onClick(() => {
                this.courierCompany = name;
                this.showCompanyPicker = false;
              })
            }
          })

          ListItem() {
            Row()
              .width('100%')
              .height(1)
              .backgroundColor($r('app.color.divider_color'))
              .margin({ top: 8, bottom: 8 })
          }
        }

        // 预设快递公司
        ListItem() {
          Text('全部快递公司')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .padding({ left: 16, top: 12, bottom: 8 })
        }

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

        // 自定义输入
        ListItem() {
          Row() {
            Text('+ 自定义快递公司')
              .fontSize(16)
              .fontColor($r('app.color.accent_blue'))
              .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .onClick(() => {
            this.showCompanyPicker = false;
            this.customCompanyName = '';
            this.showCustomCompanyInput = true;
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StationPickerSheet() {
    Column() {
      Row() {
        Text('选择驿站名称')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('自定义')
          .fontSize(16)
          .fontColor($r('app.color.accent_blue'))
          .padding({ right: 16 })
          .onClick(() => {
            this.showStationPicker = false;
            this.customStationName = '';
            this.showCustomStationInput = true;
          })
      }
      .width('100%')
      .padding(16)

      if (this.stationHistory.length > 0) {
        List() {
          ForEach(this.stationHistory, (name: string) => {
            ListItem() {
              Row() {
                Text(name)
                  .fontSize(16)
                  .fontColor($r('app.color.primary_text'))
                  .layoutWeight(1)
                
                if (this.stationName === name) {
                  Text('✓')
                    .fontSize(20)
                    .fontColor($r('app.color.accent_blue'))
                }
              }
              .width('100%')
              .padding(16)
              .onClick(() => {
                this.stationName = name;
                this.showStationPicker = false;
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          Text('暂无历史记录')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 60 })
          
          Text('请点击右上角"自定义"输入')
            .fontSize(12)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
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

  @Builder
  CustomStationInputSheet() {
    Column() {
      Text('自定义驿站名称')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 20 })

      Column() {
        TextInput({ placeholder: '请输入驿站名称', text: this.customStationName })
          .fontSize(16)
          .padding(12)
          .onChange((value: string) => {
            this.customStationName = value;
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
            this.showCustomStationInput = false;
            this.customStationName = '';
          })

        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.accent_blue'))
          .layoutWeight(1)
          .onClick(() => {
            if (this.customStationName.trim()) {
              this.stationName = this.customStationName.trim();
              this.showCustomStationInput = false;
              this.customStationName = '';
            } else {
              promptAction.showToast({ message: '请输入驿站名称', duration: 2000 });
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

