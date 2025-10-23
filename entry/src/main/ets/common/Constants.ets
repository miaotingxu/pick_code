import { CourierCompanyInfo } from '../model/ParcelModel';

/**
 * 常量配置
 */
export class Constants {
  // 数据库配置
  static readonly DB_NAME: string = 'ParcelDB.db';
  static readonly DB_VERSION: number = 1;
  static readonly TABLE_NAME: string = 'parcel_records';

  // 包裹状态
  static readonly STATUS_PENDING: number = 0; // 待取
  static readonly STATUS_PICKED: number = 1; // 已取

  // 删除标记
  static readonly NOT_DELETED: number = 0;
  static readonly DELETED: number = 1;

  // 同步状态
  static readonly NOT_SYNCED: number = 0;
  static readonly SYNCED: number = 1;

  // 快递公司配置（按业务量排序）
  static readonly COURIER_COMPANIES: CourierCompanyInfo[] = [
    { name: '顺丰速运', keyword: '顺丰|SF|sf', icon: 'shunfeng' },
    { name: '中通快递', keyword: '中通|ZTO|zto', icon: 'zhongtong' },
    { name: '申通快递', keyword: '申通|STO|sto', icon: 'shentong' },
    { name: '韵达快递', keyword: '韵达|YUNDA|yunda', icon: 'yunda' },
    { name: '极兔速递', keyword: '极兔|J&T|JT|jt', icon: 'jtexpress' },
    { name: '邮政快递', keyword: '邮政|EMS|ems|中国邮政', icon: 'youzhengguonei' },
    { name: '圆通速递', keyword: '圆通|YTO|yto', icon: 'yuantong' },
    { name: '京东快递', keyword: '京东|JD|jd', icon: 'jd' },
    { name: '百世快递', keyword: '百世|BEST|best|百世快运', icon: 'baishiwuliu' },
    { name: '德邦快递', keyword: '德邦|DEPPON|deppon', icon: 'debangwuliu' },
    { name: '安能物流', keyword: '安能|ANNENG|anneng', icon: 'annengwuliu' },
    { name: '天天快递', keyword: '天天|TTKD|ttkd', icon: 'tiantian' },
    { name: '宅急送', keyword: '宅急送|ZJS|zjs', icon: 'zhaijisong' },
    { name: '菜鸟驿站', keyword: '菜鸟|cainiao', icon: 'cainiao' },
    { name: '妈妈驿站', keyword: '妈妈驿站|妈妈', icon: 'mama' },
    { name: '兔喜生活', keyword: '兔喜|免喜|兔喜生活', icon: 'tuxi' },
  ];

  // 筛选标签（按业务量排序的主流快递公司）
  static readonly FILTER_TAGS: string[] = [
    '按时间', 
    '顺丰', 
    '中通', 
    '申通', 
    '韵达', 
    '极兔', 
    '邮政',
    '圆通',
    '京东',
    '百世',
    '其他'  // 包含：德邦、天天、宅急送、菜鸟、妈妈、兔喜等
  ];

  // 主流快递公司列表（用于筛选"其他"）
  static readonly MAIN_COURIERS: string[] = [
    '顺丰', '中通', '申通', '韵达', '极兔', '邮政', '圆通', '京东', '百世'
  ];

  // 日期格式
  static readonly DATE_FORMAT_MD: string = 'MM-dd';
  static readonly DATE_FORMAT_FULL: string = 'yyyy-MM-dd HH:mm';
  static readonly DATE_FORMAT_TIME: string = 'HH:mm';

  // UI 尺寸
  static readonly CARD_BORDER_RADIUS: number = 16;
  static readonly ICON_SIZE: number = 48;
  static readonly PADDING_NORMAL: number = 16;
  static readonly PADDING_SMALL: number = 12;
  static readonly PADDING_LARGE: number = 20;
}

