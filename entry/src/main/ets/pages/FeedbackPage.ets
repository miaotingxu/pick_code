/**
 * 用户反馈页面
 */
import { FeedbackService, FeedbackData } from '../service/FeedbackService';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

// 反馈类型接口
interface FeedbackTypeItem {
  id: string;
  label: string;
  description: string;
}

@Entry
@Component
struct FeedbackPage {
  @State feedbackContent: string = '';
  @State contactInfo: string = '';
  @State selectedType: string = 'other'; // 'bug' | 'feature' | 'other'
  @State isSubmitting: boolean = false;
  
  private feedbackService: FeedbackService = FeedbackService.getInstance();
  
  // 反馈类型选项
  private feedbackTypes: FeedbackTypeItem[] = [
    { id: 'bug', label: '🐛 Bug反馈', description: '功能异常或错误' },
    { id: 'feature', label: '💡 功能建议', description: '新功能或改进建议' },
    { id: 'other', label: '💬 其他反馈', description: '使用体验或其他问题' }
  ];

  build() {
    Column() {
      // 顶部标题栏
      this.buildTitleBar();
      
      Scroll() {
        Column() {
          // 反馈类型选择
          this.buildTypeSelector();
          
          // 反馈内容输入
          this.buildContentInput();
          
          // 联系方式输入
          this.buildContactInput();
          
          // 提示信息
          this.buildTips();
          
          // 提交按钮
          this.buildSubmitButton();
        }
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 标题栏
  @Builder
  buildTitleBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(Color.Black)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          router.back();
        })
      
      Text('意见反馈')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 占位，保持居中
      Row().width(32).height(32)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  // 反馈类型选择器
  @Builder
  buildTypeSelector() {
    Column() {
      Text('反馈类型')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)
      
      ForEach(this.feedbackTypes, (type: FeedbackTypeItem) => {
        Row() {
          Column() {
            Text(type.label)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
            
            Text(type.description)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          
          Radio({ value: type.id, group: 'feedbackType' })
            .checked(this.selectedType === type.id)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.selectedType = type.id;
              }
            })
        }
        .width('100%')
        .padding(12)
        .margin({ bottom: 8 })
        .backgroundColor(this.selectedType === type.id ? '#E8F4FF' : Color.White)
        .borderRadius(8)
        .border({
          width: 1,
          color: this.selectedType === type.id ? '#1890FF' : '#EEEEEE'
        })
        .onClick(() => {
          this.selectedType = type.id;
        })
      }, (type: FeedbackTypeItem) => type.id)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  // 反馈内容输入
  @Builder
  buildContentInput() {
    Column() {
      Text('反馈内容')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)
      
      TextArea({ 
        placeholder: '请详细描述您遇到的问题或建议...\n我们会认真对待每一条反馈 😊'
      })
        .width('100%')
        .height(180)
        .fontSize(15)
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .maxLength(500)
        .onChange((value: string) => {
          this.feedbackContent = value;
        })
      
      Row() {
        Text(`${this.feedbackContent.length}/500`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 4 })
    }
    .width('100%')
    .margin({ top: 20 })
  }

  // 联系方式输入
  @Builder
  buildContactInput() {
    Column() {
      Text('联系方式（选填）')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)
      
      TextInput({ 
        placeholder: '微信/QQ/邮箱（方便我们与您沟通）'
      })
        .width('100%')
        .height(48)
        .fontSize(15)
        .padding({ left: 12, right: 12 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .onChange((value: string) => {
          this.contactInfo = value;
        })
    }
    .width('100%')
    .margin({ top: 20 })
  }

  // 提示信息
  @Builder
  buildTips() {
    Row() {
      Text('ℹ️')
        .fontSize(16)
        .margin({ right: 8 })
      
      Text('您的反馈对我们非常重要，感谢支持！')
        .fontSize(13)
        .fontColor('#FF9800')
    }
    .width('100%')
    .padding(12)
    .margin({ top: 20 })
    .backgroundColor('#FFF3E0')
    .borderRadius(8)
  }

  // 提交按钮
  @Builder
  buildSubmitButton() {
    Button('提交反馈')
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .margin({ top: 30 })
      .enabled(!this.isSubmitting && this.feedbackContent.trim().length > 0)
      .backgroundColor(
        (!this.isSubmitting && this.feedbackContent.trim().length > 0) 
          ? '#1890FF' 
          : '#CCCCCC'
      )
      .onClick(() => {
        this.handleSubmit();
      })
    
    if (this.isSubmitting) {
      Row() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#1890FF')
          .margin({ right: 8 })
        
        Text('正在提交...')
          .fontSize(14)
          .fontColor('#666666')
      }
      .margin({ top: 12 })
    }
  }

  // 处理提交
  async handleSubmit() {
    if (this.feedbackContent.trim().length === 0) {
      promptAction.showToast({
        message: '请输入反馈内容',
        duration: 2000
      });
      return;
    }

    this.isSubmitting = true;

    const feedbackData = new FeedbackData();
    feedbackData.content = this.feedbackContent.trim();
    feedbackData.contact = this.contactInfo.trim();
    feedbackData.type = this.selectedType;

    const success = await this.feedbackService.sendFeedback(feedbackData);

    this.isSubmitting = false;

    if (success) {
      // 显示成功提示
      AlertDialog.show({
        title: '提交成功！',
        message: '感谢您的反馈，我们会尽快处理 🎉',
        confirm: {
          value: '确定',
          action: () => {
            // 清空表单
            this.feedbackContent = '';
            this.contactInfo = '';
            this.selectedType = 'other';
            // 返回上一页
            router.back();
          }
        }
      });
    } else {
      // 显示失败提示
      AlertDialog.show({
        title: '提交失败',
        message: '网络连接异常，请稍后重试',
        confirm: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }
}

