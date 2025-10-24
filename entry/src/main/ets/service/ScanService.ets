import { ParcelModel } from '../model/ParcelModel';
import { ParcelDatabase } from '../database/ParcelDatabase';
import { Constants } from '../common/Constants';
import { promptAction } from '@kit.ArkUI';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 驿站信息接口
 */
interface StationInfo {
  stationName: string;
  address: string;
}

/**
 * 扫码服务
 * 用于扫描快递单上的二维码和条形码，识别物流单号和快递公司
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
   * 启动扫码
   */
  async startScan(context: common.UIAbilityContext): Promise<void> {
    try {
      // 配置扫码选项
      const options: scanBarcode.ScanOptions = {
        scanTypes: [
          scanCore.ScanType.ALL  // 支持所有类型的条形码和二维码
        ],
        enableMultiMode: false,  // 单次扫描
        enableAlbum: true  // 允许从相册选择
      };

      // 启动扫码
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
      
      if (result && result.originalValue) {
        console.info('Scan result:', result.originalValue);
        await this.processScanResult(result.originalValue);
      } else {
        promptAction.showToast({ 
          message: '未扫描到有效内容', 
          duration: 2000 
        });
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error('Scan failed:', JSON.stringify(error));
      
      // 处理用户取消扫码的情况
      if (error.code === 1000500001) {
        // 用户取消，不显示错误提示
        return;
      }
      
      promptAction.showToast({ 
        message: '扫码失败，请重试', 
        duration: 2000 
      });
    }
  }

  /**
   * 处理扫码结果
   */
  async processScanResult(content: string): Promise<void> {
    try {
      // 解析扫码内容
      const parcel = this.parseBarcode(content);
      
      if (parcel) {
        // 保存到数据库
        const result = await this.database.insertParcel(parcel);
        
        if (result > 0) {
          // 更新快递公司和驿站的使用历史
          await this.database.addOrUpdateCourierCompany(parcel.courierCompany);
          await this.database.addOrUpdateStationName(parcel.stationName);
          
          promptAction.showToast({ 
            message: `添加成功：${parcel.courierCompany} - ${parcel.pickupCode}`, 
            duration: 2500 
          });
        } else {
          promptAction.showToast({ 
            message: '保存失败，请重试', 
            duration: 2000 
          });
        }
      } else {
        promptAction.showToast({ 
          message: '未识别到快递信息，请尝试手动添加', 
          duration: 2500 
        });
      }
    } catch (err) {
      console.error('Process scan result failed:', JSON.stringify(err));
      promptAction.showToast({ 
        message: '处理扫码结果失败', 
        duration: 2000 
      });
    }
  }

  /**
   * 解析条形码/二维码内容
   * 支持多种快递单号格式
   */
  private parseBarcode(content: string): ParcelModel | null {
    console.info('Parsing barcode content:', content);
    
    // 识别快递公司
    let courierCompany = this.identifyCourier(content);
    
    // 识别物流单号
    const trackingNumber = this.extractTrackingNumber(content, courierCompany);
    
    if (!trackingNumber) {
      console.warn('No tracking number found');
      return null;
    }

    // 提取驿站信息
    const stationInfo = this.extractStationInfo(content);

    // 获取当前时间作为取件时间
    const now = new Date();
    const pickupTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    const parcel = new ParcelModel(
      trackingNumber,
      courierCompany,
      stationInfo.stationName,
      stationInfo.address,
      pickupTime,
      Constants.STATUS_PENDING
    );

    console.info('Parsed parcel:', JSON.stringify(parcel));
    return parcel;
  }

  /**
   * 识别快递公司
   */
  private identifyCourier(content: string): string {
    // 遍历所有快递公司配置，匹配关键词
    for (const company of Constants.COURIER_COMPANIES) {
      const keywords = company.keyword.split('|');
      for (const keyword of keywords) {
        if (content.toLowerCase().includes(keyword.toLowerCase())) {
          return company.name;
        }
      }
    }

    // 如果没有匹配到，尝试根据单号格式判断
    return this.identifyByTrackingNumber(content);
  }

  /**
   * 根据单号格式识别快递公司
   */
  private identifyByTrackingNumber(trackingNumber: string): string {
    // 顺丰：12位数字，或以SF开头
    if (/^SF\d{12}$/i.test(trackingNumber) || /^\d{12}$/.test(trackingNumber)) {
      return '顺丰速运';
    }
    
    // 京东：以JD开头 + 10-15位数字
    if (/^JD\d{10,15}$/i.test(trackingNumber)) {
      return '京东快递';
    }
    
    // EMS/邮政：13位字母+数字，通常以E开头，以CN结尾
    if (/^E\w{12}CN$/i.test(trackingNumber) || /^[A-Z]{2}\d{9}[A-Z]{2}$/i.test(trackingNumber)) {
      return '邮政快递';
    }
    
    // 中通/圆通/申通/韵达等：通常是纯数字，10-15位
    if (/^\d{10,15}$/.test(trackingNumber)) {
      // 这些快递公司的单号格式相似，无法精确区分，返回"未知快递"
      return '未知快递';
    }

    return '未知快递';
  }

  /**
   * 提取物流单号
   */
  private extractTrackingNumber(content: string, courierCompany: string): string {
    // 1. 尝试匹配取件码格式（如：6-2-2175, 2-5-2418）
    const pickupCodeMatch = content.match(/(\d+-\d+-\d+)/);
    if (pickupCodeMatch) {
      return pickupCodeMatch[1];
    }

    // 2. 尝试匹配完整的物流单号格式
    
    // 顺丰单号：SF + 12位数字，或纯12位数字
    if (courierCompany === '顺丰速运') {
      const sfMatch = content.match(/SF\d{12}|\d{12}/i);
      if (sfMatch) return sfMatch[0];
    }

    // 京东单号：JD + 10-15位数字
    if (courierCompany === '京东快递') {
      const jdMatch = content.match(/JD\d{10,15}/i);
      if (jdMatch) return jdMatch[0];
    }

    // EMS/邮政单号
    if (courierCompany === '邮政快递') {
      const emsMatch = content.match(/E\w{12}CN|[A-Z]{2}\d{9}[A-Z]{2}/i);
      if (emsMatch) return emsMatch[0];
    }

    // 3. 通用匹配：10-20位的纯数字（大部分快递公司）
    const numberMatch = content.match(/\d{10,20}/);
    if (numberMatch) {
      return numberMatch[0];
    }

    // 4. 匹配混合字母数字（10-20位）
    const alphanumericMatch = content.match(/[A-Z0-9]{10,20}/i);
    if (alphanumericMatch) {
      return alphanumericMatch[0];
    }

    // 如果都没匹配到，返回原始内容（截取前30个字符）
    return content.substring(0, 30);
  }

  /**
   * 提取驿站信息
   */
  private extractStationInfo(content: string): StationInfo {
    let stationName = '驿站';
    let address = '';

    // 提取驿站名称（匹配常见的驿站关键词）
    const stationPatterns = [
      /(.{2,10}?驿站)/,
      /(.{2,10}?超市)/,
      /(.{2,10}?便利店)/,
      /(.{2,10}?商店)/,
      /(菜鸟[^，。\s]{0,10})/,
      /(兔喜[^，。\s]{0,10})/,
      /(妈妈[^，。\s]{0,10})/,
    ];

    for (const pattern of stationPatterns) {
      const match = content.match(pattern);
      if (match) {
        stationName = match[1];
        break;
      }
    }

    // 提取地址信息
    const addressPatterns = [
      /地址[：:]\s*(.{5,50}?)(?:[，。\n]|$)/,
      /位置[：:]\s*(.{5,50}?)(?:[，。\n]|$)/,
      /详细地址[：:]\s*(.{5,50}?)(?:[，。\n]|$)/,
    ];

    for (const pattern of addressPatterns) {
      const match = content.match(pattern);
      if (match) {
        address = match[1].trim();
        break;
      }
    }

    // 如果没有明确的地址标识，尝试提取包含省市区的字符串
    if (!address) {
      const locationMatch = content.match(/.{0,5}?(省|市|区|县|镇|街道|路|号).{5,30}?(?:[，。\n]|$)/);
      if (locationMatch) {
        address = locationMatch[0].trim();
      }
    }

    return {
      stationName: stationName,
      address: address || '请手动补充地址'
    };
  }
}
