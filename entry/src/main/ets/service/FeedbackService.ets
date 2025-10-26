/**
 * 用户反馈服务
 * 通过飞书 Webhook 收集用户需求和反馈
 */
import http from '@ohos.net.http';
import deviceInfo from '@ohos.deviceInfo';

export class FeedbackData {
  content: string = '';
  contact?: string;
  type?: string;
  deviceInfo?: DeviceInfo;
}

class DeviceInfo {
  model: string = '';
  osVersion: string = '';
  appVersion: string = '';
}

export class FeedbackService {
  private static instance: FeedbackService;
  
  // ⚠️ 重要：将这里替换为你的飞书 Webhook 地址
  private static readonly WEBHOOK_URL = 'https://open.feishu.cn/open-apis/bot/v2/hook/21470c0d-7155-49cb-b0c3-1e5030fc4edb';
  
  static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }

  /**
   * 发送用户反馈到飞书群
   * @param feedbackData 反馈数据
   * @returns Promise<boolean> 是否发送成功
   */
  async sendFeedback(feedbackData: FeedbackData): Promise<boolean> {
    try {
      // 获取设备信息
      const deviceInfoData: DeviceInfo = {
        model: deviceInfo.marketName || deviceInfo.productModel || '未知设备',
        osVersion: deviceInfo.osFullName || '未知版本',
        appVersion: '1.0.0' // 可以从配置读取
      };

      // 构建飞书消息卡片（已经是 JSON 字符串）
      const messageJson = this.buildFeishuCard(feedbackData, deviceInfoData);

      // 发送 HTTP 请求
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        FeedbackService.WEBHOOK_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: messageJson,
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );

      // 清理请求对象
      httpRequest.destroy();

      // 检查响应
      if (response.responseCode === 200) {
        console.info('[FeedbackService] 反馈发送成功');
        return true;
      } else {
        console.error('[FeedbackService] 反馈发送失败:', response.responseCode);
        return false;
      }
    } catch (error) {
      console.error('[FeedbackService] 发送反馈异常:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 构建飞书消息卡片
   */
  private buildFeishuCard(feedbackData: FeedbackData, deviceInfoData: DeviceInfo): string {
    // 反馈类型的中文映射
    let feedbackType = '💬 其他反馈';
    if (feedbackData.type === 'bug') {
      feedbackType = '🐛 Bug反馈';
    } else if (feedbackData.type === 'feature') {
      feedbackType = '💡 功能建议';
    }
    
    // 当前时间
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');
    const second = String(now.getSeconds()).padStart(2, '0');
    const timeStr = `${year}-${month}-${day} ${hour}:${minute}:${second}`;
    
    // 转义 JSON 字符串中的特殊字符
    const escapeJson = (str: string): string => {
      return str.replace(/\\/g, '\\\\')
        .replace(/"/g, '\\"')
        .replace(/\n/g, '\\n')
        .replace(/\r/g, '\\r')
        .replace(/\t/g, '\\t');
    };
    
    const content = escapeJson(feedbackData.content);
    const contact = escapeJson(feedbackData.contact || '未提供');
    const model = escapeJson(deviceInfoData.model);
    const osVersion = escapeJson(deviceInfoData.osVersion);
    const appVersion = escapeJson(deviceInfoData.appVersion);

    // 直接构建 JSON 字符串，完全避免数组字面量类型推断
    const message = '{"msg_type":"interactive","card":{"header":{"title":{"tag":"plain_text","content":"📬 收到新的用户反馈"},"template":"blue"},"elements":[' +
      '{"tag":"div","text":{"tag":"lark_md","content":"**反馈类型：**\\n' + feedbackType + '"}},' +
      '{"tag":"hr"},' +
      '{"tag":"div","text":{"tag":"lark_md","content":"**反馈内容：**\\n' + content + '"}},' +
      '{"tag":"hr"},' +
      '{"tag":"div","fields":[' +
        '{"is_short":true,"text":{"tag":"lark_md","content":"**联系方式：**\\n' + contact + '"}},' +
        '{"is_short":true,"text":{"tag":"lark_md","content":"**提交时间：**\\n' + timeStr + '"}}' +
      ']},' +
      '{"tag":"hr"},' +
      '{"tag":"div","text":{"tag":"lark_md","content":"**设备信息：**\\n设备：' + model + '\\n系统：' + osVersion + '\\n应用版本：' + appVersion + '"}},' +
      '{"tag":"note","elements":[{"tag":"plain_text","content":"来自 PickCode 用户反馈系统"}]}' +
    ']}}';
    
    return message;
  }

  /**
   * 快速发送文本反馈（简化版）
   */
  async sendQuickFeedback(content: string): Promise<boolean> {
    return await this.sendFeedback({
      content: content,
      type: 'other'
    });
  }
}

