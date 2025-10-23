import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

/**
 * 短信读取服务
 * 用于自动提取短信中的取件码信息
 */
export class SmsService {
  private static instance: SmsService;
  private database: ParcelDatabase = ParcelDatabase.getInstance();

  static getInstance(): SmsService {
    if (!SmsService.instance) {
      SmsService.instance = new SmsService();
    }
    return SmsService.instance;
  }

  /**
   * 检查并请求短信读取权限
   */
  async requestPermission(context: Context): Promise<boolean> {
    const permissions: Array<Permissions> = ['ohos.permission.READ_MESSAGES'];
    const atManager = abilityAccessCtrl.createAtManager();

    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenId = bundleInfo.appInfo.accessTokenId;

      // 检查权限
      const authStatus = await atManager.checkAccessToken(tokenId, permissions[0]);
      if (authStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }

      // 请求权限
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      return result.authResults[0] === 0;
    } catch (error) {
      console.error('Request permission failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 解析短信内容，提取取件码信息
   */
  parseSmsContent(content: string): ParcelModel | null {
    // 取件码格式匹配（支持多种格式）
    // 例如: 2-5-2418, 8-8-2288, 3-3-8207, 3-2-926
    const pickupCodePattern = /取件码[：:]\s*(\d+-\d+-\d+)/i;
    let pickupCodeMatch = content.match(pickupCodePattern);

    if (!pickupCodeMatch) {
      // 尝试匹配其他格式
      const altPattern = /验证码[：:]\s*(\d+-\d+-\d+)/i;
      pickupCodeMatch = content.match(altPattern);
      if (!pickupCodeMatch) {
        return null;
      }
    }

    const pickupCode = pickupCodeMatch[1];

    // 识别快递公司
    let courierCompany = '未知快递';
    for (const company of Constants.COURIER_COMPANIES) {
      const regex = new RegExp(company.keyword, 'i');
      if (regex.test(content)) {
        courierCompany = company.name;
        break;
      }
    }

    // 提取驿站名称
    let stationName = '';
    const stationPatterns = [
      /在(.+?驿站)/,
      /(.+?驿站)/,
      /在(.+?超市)/,
      /(.+?超市)/,
      /在(.+?店)/
    ];

    for (const pattern of stationPatterns) {
      const match = content.match(pattern);
      if (match) {
        stationName = match[1];
        break;
      }
    }

    if (!stationName) {
      stationName = '驿站';
    }

    // 提取地址信息
    let address = '';
    const addressPattern = /地址[：:]\s*(.+?)(?:[，。]|$)/;
    const addressMatch = content.match(addressPattern);
    if (addressMatch) {
      address = addressMatch[1];
    }

    // 获取当前时间
    const now = new Date();
    const pickupTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    return new ParcelModel(
      pickupCode,
      courierCompany,
      stationName,
      address,
      pickupTime,
      Constants.STATUS_PENDING
    );
  }

  /**
   * 监听短信（实际实现需要使用系统短信监听接口）
   * 注意：鸿蒙系统的短信监听接口可能需要系统级权限
   */
  async startSmsListener(context: Context): Promise<void> {
    // 检查权限
    const hasPermission = await this.requestPermission(context);
    if (!hasPermission) {
      console.warn('SMS permission not granted');
      return;
    }

    // TODO: 实现短信监听
    // 由于鸿蒙系统的短信监听API可能有限制，这里提供思路：
    // 1. 使用系统消息通知监听
    // 2. 定期扫描短信数据库（需要额外权限）
    // 3. 引导用户手动分享短信内容到应用

    console.info('SMS listener started');
  }

  /**
   * 手动处理短信内容
   */
  async processSmsContent(content: string): Promise<boolean> {
    const parcel = this.parseSmsContent(content);
    if (parcel) {
      const result = await this.database.insertParcel(parcel);
      return result > 0;
    }
    return false;
  }

  /**
   * 批量解析短信内容
   * @param smsMessages 短信内容数组
   * @returns 解析成功的包裹列表
   */
  parseBatchSms(smsMessages: string[]): ParcelModel[] {
    const parcels: ParcelModel[] = [];
    
    for (const sms of smsMessages) {
      const parcel = this.parseSmsContent(sms);
      if (parcel) {
        parcels.push(parcel);
      }
    }
    
    return parcels;
  }

  /**
   * 通知监听功能（已禁用）
   * 原因：需要系统级权限 NOTIFICATION_CONTROLLER，普通应用无法使用
   * 替代方案：使用短信分享导入或剪贴板导入功能
   */
  async startNotificationListener(context: Context, callback: (smsContent: string) => void): Promise<boolean> {
    console.warn('Notification listener is not available for regular apps');
    console.warn('Please use SMS sharing or clipboard import instead');
    return false;
  }

  /**
   * 判断是否是快递通知
   */
  private isDeliveryNotification(content: string): boolean {
    // 关键词列表
    const keywords = [
      '取件码', '验证码', '快递', '包裹', '驿站',
      '菜鸟', '妈妈驿站', '兔喜',
      '顺丰', '中通', '圆通', '申通', '韵达',
      '极兔', '京东', '邮政', 'EMS'
    ];

    // 检查是否包含任何关键词
    for (const keyword of keywords) {
      if (content.includes(keyword)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 检查短信内容是否包含取件码
   */
  hasPickupCode(content: string): boolean {
    const pickupCodePattern = /取件码[：:]\s*(\d+-\d+-\d+)/i;
    const altPattern = /验证码[：:]\s*(\d+-\d+-\d+)/i;
    const longCodePattern = /[A-Z]{2}\d{10,}/; // SF1234567890, JD8888888888
    
    return pickupCodePattern.test(content) || 
           altPattern.test(content) ||
           longCodePattern.test(content);
  }
}

