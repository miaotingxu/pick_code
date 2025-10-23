/**
 * 快递包裹数据模型
 */
export class ParcelModel {
  id?: number; // 主键
  pickupCode: string; // 取件码
  courierCompany: string; // 快递公司
  stationName: string; // 驿站名称
  address: string; // 详细地址
  pickupTime: string; // 取件时间
  status: number; // 状态：0-待取，1-已取
  createTime: number; // 创建时间戳
  isDeleted: number; // 删除标记：0-未删除，1-已删除
  syncStatus: number; // 同步状态：0-未同步，1-已同步（预留云端同步）

  constructor(
    pickupCode: string,
    courierCompany: string,
    stationName: string,
    address: string,
    pickupTime: string,
    status: number = 0
  ) {
    this.pickupCode = pickupCode;
    this.courierCompany = courierCompany;
    this.stationName = stationName;
    this.address = address;
    this.pickupTime = pickupTime;
    this.status = status;
    this.createTime = Date.now();
    this.isDeleted = 0;
    this.syncStatus = 0;
  }
}

/**
 * 快递公司信息
 */
export interface CourierCompanyInfo {
  name: string; // 快递公司名称
  keyword: string; // 匹配关键词
  icon: string; // 图标资源名称
}

