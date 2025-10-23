/**
 * 图标工具类
 * 用于处理快递公司图标
 */
export class IconUtils {
  /**
   * 获取快递公司颜色（按业务量排序）
   */
  static getCourierColor(company: string): string {
    const colorMap: Record<string, string> = {
      // 主流快递公司
      '顺丰速运': '#4CAF50',    // 绿色（高端品牌色）
      '中通快递': '#4ECDC4',    // 青色
      '申通快递': '#FFC107',    // 黄色
      '韵达快递': '#9B59B6',    // 紫色
      '极兔速递': '#95E1D3',    // 薄荷绿
      '邮政快递': '#00BCD4',    // 蓝色
      '圆通速递': '#FF6B6B',    // 红色
      '京东快递': '#E53935',    // 京东红
      '百世快递': '#FF5722',    // 深橙色
      '德邦快递': '#3F51B5',    // 靛蓝色
      '安能物流': '#00897B',    // 青绿色
      '天天快递': '#009688',    // 青绿色
      '宅急送': '#795548',      // 棕色
      // 驿站
      '菜鸟驿站': '#FF9800',    // 橙色
      '妈妈驿站': '#E91E63',    // 粉色
      '兔喜生活': '#2196F3'     // 蓝色
    };
    
    return colorMap[company] || '#9E9E9E';
  }

  /**
   * 获取快递公司缩写（用于文字图标备选）
   */
  static getCourierAbbr(company: string): string {
    const abbrMap: Record<string, string> = {
      // 主流快递公司
      '顺丰速运': 'SF',
      '中通快递': 'ZT',
      '申通快递': 'ST',
      '韵达快递': 'YD',
      '极兔速递': 'JT',
      '邮政快递': 'EMS',
      '圆通速递': 'YT',
      '京东快递': 'JD',
      '百世快递': 'BS',
      '德邦快递': 'DB',
      '安能物流': 'AN',
      '天天快递': 'TT',
      '宅急送': 'ZJS',
      // 驿站
      '菜鸟驿站': 'CN',
      '妈妈驿站': 'MM',
      '兔喜生活': 'TX'
    };
    
    return abbrMap[company] || company.substring(0, 2);
  }
}

