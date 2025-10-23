import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private pendingSmsContent: string = '';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    // 检查是否是通过分享启动
    this.handleShareIntent(want);
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    // 处理新的分享意图
    this.handleShareIntent(want);
  }
  
  // 处理分享意图
  private handleShareIntent(want: Want): void {
    if (want.action === 'ohos.want.action.sendData') {
      // 获取分享的文本内容
      const sharedText = want.parameters?.['ability.params.stream'] as string;
      if (sharedText) {
        hilog.info(DOMAIN, 'testTag', 'Received shared text: %{public}s', sharedText);
        this.pendingSmsContent = sharedText;
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 判断是否有分享的短信内容
    if (this.pendingSmsContent) {
      // 跳转到短信导入页面
      windowStage.loadContent('pages/SmsImport', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load SmsImport page. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading SmsImport page.');
        
        // 通过 AppStorage 传递数据
        AppStorage.setOrCreate('pendingSmsContent', this.pendingSmsContent);
        this.pendingSmsContent = ''; // 清空
      });
    } else {
      // 正常启动，加载主页
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}