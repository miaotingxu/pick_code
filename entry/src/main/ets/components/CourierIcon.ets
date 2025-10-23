import { IconUtils } from '../utils/IconUtils';

/**
 * 快递公司图标组件
 * 自动判断是否有真实图标，无则使用文字图标
 */
@Component
export struct CourierIcon {
  @Prop courierCompany: string;
  @Prop size: number = 48;
  @Prop borderRadius: number = 8;
  @State useRealIcon: boolean = false; // 是否使用真实图标

  build() {
    Stack() {
      if (this.useRealIcon) {
        // 使用真实图标
        Image(this.getCourierIconResource())
          .width(this.size)
          .height(this.size)
          .borderRadius(this.borderRadius)
          .objectFit(ImageFit.Cover)
      } else {
        // 使用文字图标（优化版）
        Stack() {
          Text(IconUtils.getCourierAbbr(this.courierCompany))
            .fontSize(this.size * 0.35)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textShadow({ radius: 2, color: '#40000000', offsetX: 0, offsetY: 1 })
        }
        .width(this.size)
        .height(this.size)
        .backgroundColor(IconUtils.getCourierColor(this.courierCompany))
        .borderRadius(this.borderRadius)
        .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
      }
    }
  }

  // 获取快递公司图标资源
  getCourierIconResource(): Resource {
    const lowerCompany = this.courierCompany.toLowerCase();
    
    // 根据公司名称返回对应图标
    if (lowerCompany.includes('顺丰') || lowerCompany.includes('sf')) {
      return $r('app.media.shunfeng');
    } else if (lowerCompany.includes('中通') || lowerCompany.includes('zto')) {
      return $r('app.media.zto');
    } else if (lowerCompany.includes('申通') || lowerCompany.includes('sto')) {
      return $r('app.media.shentong');
    } else if (lowerCompany.includes('韵达')) {
      return $r('app.media.yunda');
    } else if (lowerCompany.includes('极兔') || lowerCompany.includes('jt')) {
      return $r('app.media.jt');
    } else if (lowerCompany.includes('邮政') || lowerCompany.includes('ems')) {
      return $r('app.media.ems');
    } else if (lowerCompany.includes('圆通') || lowerCompany.includes('yto')) {
      return $r('app.media.yto');
    } else if (lowerCompany.includes('京东') || lowerCompany.includes('jd')) {
      return $r('app.media.jd');
    } else if (lowerCompany.includes('百世')) {
      return $r('app.media.baishi');
    } else if (lowerCompany.includes('德邦')) {
      return $r('app.media.debang');
    } else if (lowerCompany.includes('天天')) {
      return $r('app.media.tiantian');
    } else if (lowerCompany.includes('宅急送')) {
      return $r('app.media.zhaijisong');
    } else if (lowerCompany.includes('菜鸟')) {
      return $r('app.media.cainiao');
    } else if (lowerCompany.includes('妈妈')) {
      return $r('app.media.mama');
    } else if (lowerCompany.includes('兔喜') || lowerCompany.includes('免喜')) {
      return $r('app.media.tuxi');
    }
    
    // 默认图标
    return $r('app.media.startIcon');
  }
}

