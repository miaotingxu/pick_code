import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import { promptAction } from '@kit.ArkUI';

/**
 * 扫码服务
 * 用于扫描快递单上的二维码和条形码
 * 注意：当前版本暂未实现扫码功能（等待 HarmonyOS API 支持）
 */
export class ScanService {
  private static instance: ScanService;
  private database: ParcelDatabase = ParcelDatabase.getInstance();

  static getInstance(): ScanService {
    if (!ScanService.instance) {
      ScanService.instance = new ScanService();
    }
    return ScanService.instance;
  }

  /**
   * 启动扫码（暂未实现）
   */
  async startScan(context: Context): Promise<void> {
    try {
      // TODO: 等待 HarmonyOS scanBarcode API 支持
      // 当前版本提示用户手动输入
      promptAction.showToast({ 
        message: '扫码功能开发中，请使用手动添加', 
        duration: 2000 
      });
      
      // 未来实现示例：
      // const result = await scanBarcode.startScanForResult(context, options);
      // if (result && result.originalValue) {
      //   await this.processScanResult(result.originalValue);
      // }
    } catch (err) {
      const error = err as Error;
      console.error('Scan failed:', JSON.stringify(error));
      promptAction.showToast({ message: '扫码失败', duration: 2000 });
    }
  }

  /**
   * 处理扫码结果
   */
  async processScanResult(content: string): Promise<void> {
    // 解析扫码内容
    const parcel = this.parseBarcode(content);
    
    if (parcel) {
      const result = await this.database.insertParcel(parcel);
      if (result > 0) {
        promptAction.showToast({ message: '添加成功', duration: 2000 });
      } else {
        promptAction.showToast({ message: '添加失败', duration: 2000 });
      }
    } else {
      promptAction.showToast({ message: '未识别到取件码信息', duration: 2000 });
    }
  }

  /**
   * 解析条形码/二维码内容
   */
  private parseBarcode(content: string): ParcelModel | null {
    // 尝试匹配取件码格式
    const pickupCodePattern = /(\d+-\d+-\d+)/;
    const match = content.match(pickupCodePattern);
    
    if (!match) {
      return null;
    }

    const pickupCode = match[1];

    // 识别快递公司
    let courierCompany = '未知快递';
    for (const company of Constants.COURIER_COMPANIES) {
      const regex = new RegExp(company.keyword, 'i');
      if (regex.test(content)) {
        courierCompany = company.name;
        break;
      }
    }

    // 提取驿站信息
    let stationName = '驿站';
    const stationPattern = /(.+?驿站|.+?超市|.+?店)/;
    const stationMatch = content.match(stationPattern);
    if (stationMatch) {
      stationName = stationMatch[1];
    }

    // 提取地址
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
}

