# 快递公司图标说明

## 当前状态

应用当前使用**彩色文字图标**作为快递公司的标识，每个快递公司都有独特的颜色和缩写。

## 图标映射

| 快递公司 | 缩写 | 颜色 | 图标文件名 |
|---------|------|------|-----------|
| 圆通速递 | YT | #FF6B6B | yto.png |
| 中通快递 | ZT | #4ECDC4 | zto.png |
| 极兔速递 | JT | #95E1D3 | jt.png |
| 京东快递 | JD | #E53935 | jd.png |
| 韵达快递 | YD | #9B59B6 | yunda.png |
| 菜鸟驿站 | CN | #FF9800 | cainiao.png |
| 妈妈驿站 | MM | #E91E63 | mama.png |
| 免喜生活 | MX | #2196F3 | mianxi.png |
| 顺丰速运 | SF | #4CAF50 | shunfeng.png |
| 申通快递 | ST | #FFC107 | shentong.png |
| 邮政快递 | EMS | #00BCD4 | ems.png |

## 如何添加真实图标

### 1. 准备图标文件

准备各快递公司的 Logo 图标，建议规格：
- 格式：PNG（支持透明背景）
- 尺寸：建议 128x128px 或更高
- 命名：按照上表中的"图标文件名"列命名

### 2. 添加到资源目录

将图标文件复制到以下目录：
```
entry/src/main/resources/base/media/
```

### 3. 修改代码使用真实图标

打开 `entry/src/main/ets/pages/Index.ets` 文件，找到 `ParcelCard` 方法中的图标部分：

**当前代码（文字图标）：**
```typescript
// 左侧：快递公司图标（文字图标）
Stack() {
  Circle({ width: 48, height: 48 })
    .fill(this.getCourierColor(parcel.courierCompany))
  
  Text(this.getCourierAbbr(parcel.courierCompany))
    .fontSize(14)
    .fontWeight(FontWeight.Bold)
    .fontColor(Color.White)
}
.width(48)
.height(48)
.margin({ right: 12 })
```

**修改为真实图标：**
```typescript
// 左侧：快递公司图标
Image(this.getCourierIcon(parcel.courierCompany))
  .width(48)
  .height(48)
  .borderRadius(24)
  .margin({ right: 12 })
```

### 4. 添加图标获取方法

在 `Index.ets` 中添加以下方法：

```typescript
// 获取快递公司图标
getCourierIcon(company: string): Resource {
  const lowerCompany = company.toLowerCase();
  
  if (lowerCompany.includes('极兔') || lowerCompany.includes('jt')) {
    return $r('app.media.jt');
  } else if (lowerCompany.includes('中通') || lowerCompany.includes('zto')) {
    return $r('app.media.zto');
  } else if (lowerCompany.includes('圆通') || lowerCompany.includes('yto')) {
    return $r('app.media.yto');
  } else if (lowerCompany.includes('京东') || lowerCompany.includes('jd')) {
    return $r('app.media.jd');
  } else if (lowerCompany.includes('韵达')) {
    return $r('app.media.yunda');
  } else if (lowerCompany.includes('菜鸟')) {
    return $r('app.media.cainiao');
  } else if (lowerCompany.includes('妈妈')) {
    return $r('app.media.mama');
  } else if (lowerCompany.includes('免喜')) {
    return $r('app.media.mianxi');
  } else if (lowerCompany.includes('顺丰')) {
    return $r('app.media.shunfeng');
  } else if (lowerCompany.includes('申通')) {
    return $r('app.media.shentong');
  } else if (lowerCompany.includes('邮政') || lowerCompany.includes('ems')) {
    return $r('app.media.ems');
  }
  
  // 默认图标
  return $r('app.media.startIcon');
}
```

## 图标资源来源

您可以从以下渠道获取快递公司图标：

1. **官方网站**
   - 访问各快递公司官网下载官方 Logo

2. **图标库网站**
   - [Iconfont](https://www.iconfont.cn/)
   - [IconPark](https://iconpark.oceanengine.com/)
   - [Font Awesome](https://fontawesome.com/)

3. **设计规范**
   - 确保获得授权使用
   - 保持统一的尺寸和风格
   - 建议使用圆形或圆角方形背景

## 注意事项

1. **版权问题**
   - 使用快递公司 Logo 前请确认是否需要授权
   - 建议仅用于个人学习和非商业用途

2. **图标一致性**
   - 保持所有图标尺寸一致
   - 建议统一使用圆形或方形样式
   - 背景色可以使用快递公司品牌色

3. **性能优化**
   - 图标文件不宜过大（建议 < 50KB）
   - 可以使用 WebP 格式减小文件体积

## 当前文字图标的优势

虽然真实图标更美观，但当前的文字图标方案也有其优势：

- ✅ 不需要准备图标资源
- ✅ 加载速度快
- ✅ 颜色鲜明易于区分
- ✅ 无版权问题
- ✅ 支持任意快递公司

如果您只是测试或个人使用，可以继续使用文字图标。

