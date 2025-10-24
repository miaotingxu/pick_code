import { describe, it, expect } from '@ohos/hypium';
import { ScanService } from '../main/ets/service/ScanService';

/**
 * 扫码服务单元测试
 * 
 * 测试场景：
 * 1. 取件码格式识别
 * 2. 快递公司识别
 * 3. 物流单号提取
 * 4. 驿站信息提取
 */
export default function scanServiceTest() {
  describe('ScanService', () => {
    const scanService = ScanService.getInstance();

    /**
     * 测试场景 1: 中通快递取件码
     */
    it('should parse 中通快递 pickup code correctly', () => {
      const input = '中通快递\n取件码：6-2-2175\n菜鸟驿站\n地址：杭州万泰凤华新建店';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('6-2-2175');
      expect(result?.courierCompany).assertEqual('中通快递');
      expect(result?.stationName).toContain('驿站');
    });

    /**
     * 测试场景 2: 顺丰快递单号
     */
    it('should identify 顺丰速运 by tracking number', () => {
      const input = 'SF123456789012';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('SF123456789012');
      expect(result?.courierCompany).assertEqual('顺丰速运');
    });

    /**
     * 测试场景 3: 京东快递单号
     */
    it('should identify 京东快递 by tracking number', () => {
      const input = 'JD8888888888';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('JD8888888888');
      expect(result?.courierCompany).assertEqual('京东快递');
    });

    /**
     * 测试场景 4: 邮政快递单号
     */
    it('should identify 邮政快递 by tracking number', () => {
      const input = 'EA123456789CN';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('EA123456789CN');
      expect(result?.courierCompany).assertEqual('邮政快递');
    });

    /**
     * 测试场景 5: 极兔速递取件码
     */
    it('should parse 极兔速递 pickup code correctly', () => {
      const input = '极兔速递 取件码：2-5-2418 兔喜生活';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('2-5-2418');
      expect(result?.courierCompany).assertEqual('极兔速递');
    });

    /**
     * 测试场景 6: 圆通速递取件码
     */
    it('should parse 圆通速递 pickup code correctly', () => {
      const input = 'YTO 圆通速递\n6-3-1234\n菜鸟驿站 杭州万泰凤华新建店';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('6-3-1234');
      expect(result?.courierCompany).assertEqual('圆通速递');
    });

    /**
     * 测试场景 7: 未知快递（纯数字单号）
     */
    it('should handle unknown courier with numeric tracking number', () => {
      const input = '7890123456789';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('7890123456789');
      // 未知快递也应该能保存
      expect(result?.courierCompany).toBeDefined();
    });

    /**
     * 测试场景 8: 驿站信息提取
     */
    it('should extract station info correctly', () => {
      const input = '中通快递 6-2-2175 菜鸟驿站 地址：杭州市西湖区文一路123号';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.stationName).toContain('菜鸟');
      expect(result?.address).toContain('杭州');
    });

    /**
     * 测试场景 9: 无效内容
     */
    it('should return null for invalid content', () => {
      const input = 'Hello World';
      const result = scanService['parseBarcode'](input);
      
      // 无效内容应该返回 null
      expect(result).toBeNull();
    });

    /**
     * 测试场景 10: 复杂二维码内容
     */
    it('should parse complex QR code content', () => {
      const input = `
        快递公司：中通快递
        运单号：78901234567890
        取件码：6-2-2175
        驿站名称：菜鸟驿站
        详细地址：浙江省杭州市西湖区文一路123号
        联系电话：0571-12345678
      `;
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('6-2-2175');
      expect(result?.courierCompany).assertEqual('中通快递');
      expect(result?.stationName).toContain('菜鸟');
      expect(result?.address).toContain('杭州');
    });

    /**
     * 测试场景 11: 关键词大小写不敏感
     */
    it('should be case insensitive for courier names', () => {
      const input1 = 'sf123456789012';
      const input2 = 'SF123456789012';
      const input3 = 'Sf123456789012';
      
      const result1 = scanService['parseBarcode'](input1);
      const result2 = scanService['parseBarcode'](input2);
      const result3 = scanService['parseBarcode'](input3);
      
      expect(result1?.courierCompany).assertEqual('顺丰速运');
      expect(result2?.courierCompany).assertEqual('顺丰速运');
      expect(result3?.courierCompany).assertEqual('顺丰速运');
    });

    /**
     * 测试场景 12: 韵达快递
     */
    it('should identify 韵达快递 correctly', () => {
      const input = '韵达快递 7-1-9876 菜鸟驿站';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('7-1-9876');
      expect(result?.courierCompany).assertEqual('韵达快递');
    });

    /**
     * 测试场景 13: 申通快递
     */
    it('should identify 申通快递 correctly', () => {
      const input = 'STO 申通快递 8-2-5432';
      const result = scanService['parseBarcode'](input);
      
      expect(result).not.toBeNull();
      expect(result?.pickupCode).assertEqual('8-2-5432');
      expect(result?.courierCompany).assertEqual('申通快递');
    });
  });
}

