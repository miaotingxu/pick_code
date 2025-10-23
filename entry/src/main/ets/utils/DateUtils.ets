/**
 * 日期工具类
 */
export class DateUtils {
  /**
   * 格式化日期为 MM-dd 格式
   */
  static formatDateMD(timestamp: number): string {
    const date = new Date(timestamp);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${month}-${day}`;
  }

  /**
   * 格式化日期为 yyyy-MM-dd HH:mm 格式
   */
  static formatDateTimeFull(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  /**
   * 格式化时间为 HH:mm 格式
   */
  static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 获取当前时间字符串 HH:mm
   */
  static getCurrentTime(): string {
    return DateUtils.formatTime(Date.now());
  }

  /**
   * 判断是否为今天
   */
  static isToday(timestamp: number): boolean {
    const date = new Date(timestamp);
    const today = new Date();
    return date.getFullYear() === today.getFullYear() &&
           date.getMonth() === today.getMonth() &&
           date.getDate() === today.getDate();
  }

  /**
   * 获取相对时间描述（今天、昨天等）
   */
  static getRelativeTime(timestamp: number): string {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);

    if (DateUtils.isSameDay(date, today)) {
      return '今天';
    } else if (DateUtils.isSameDay(date, yesterday)) {
      return '昨天';
    } else {
      return DateUtils.formatDateMD(timestamp);
    }
  }

  /**
   * 判断两个日期是否为同一天
   */
  private static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
  }
}

