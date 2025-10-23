import relationalStore from '@ohos.data.relationalStore';
import { ParcelModel } from '../model/ParcelModel';
import { Constants } from '../common/Constants';

/**
 * 快递包裹数据库管理类
 */
export class ParcelDatabase {
  private rdbStore: relationalStore.RdbStore | null = null;
  private static instance: ParcelDatabase;

  // 单例模式
  static getInstance(): ParcelDatabase {
    if (!ParcelDatabase.instance) {
      ParcelDatabase.instance = new ParcelDatabase();
    }
    return ParcelDatabase.instance;
  }

  /**
   * 初始化数据库
   */
  async initDB(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: Constants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTable();
    } catch (error) {
      console.error('Database initialization failed:', JSON.stringify(error));
      throw new Error('数据库初始化失败，请重启应用');
    }
  }

  /**
   * 创建表
   */
  private async createTable(): Promise<void> {
    // 包裹记录表
    const createTableSql = `
      CREATE TABLE IF NOT EXISTS ${Constants.TABLE_NAME} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pickupCode TEXT NOT NULL,
        courierCompany TEXT NOT NULL,
        stationName TEXT NOT NULL,
        address TEXT,
        pickupTime TEXT,
        status INTEGER DEFAULT 0,
        createTime INTEGER,
        isDeleted INTEGER DEFAULT 0,
        syncStatus INTEGER DEFAULT 0
      )
    `;

    // 快递公司历史记录表
    const createCourierTableSql = `
      CREATE TABLE IF NOT EXISTS courier_companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        useCount INTEGER DEFAULT 1,
        lastUsedTime INTEGER,
        createTime INTEGER
      )
    `;

    // 驿站名称历史记录表
    const createStationTableSql = `
      CREATE TABLE IF NOT EXISTS station_names (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        useCount INTEGER DEFAULT 1,
        lastUsedTime INTEGER,
        createTime INTEGER
      )
    `;

    if (this.rdbStore) {
      try {
        await this.rdbStore.executeSql(createTableSql);
        await this.rdbStore.executeSql(createCourierTableSql);
        await this.rdbStore.executeSql(createStationTableSql);
        console.info('All tables created successfully');
      } catch (err) {
        console.error('Create table failed:', JSON.stringify(err));
        throw new Error('创建数据表失败');
      }
    }
  }

  /**
   * 插入包裹记录
   */
  async insertParcel(parcel: ParcelModel): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'pickupCode': parcel.pickupCode,
      'courierCompany': parcel.courierCompany,
      'stationName': parcel.stationName,
      'address': parcel.address,
      'pickupTime': parcel.pickupTime,
      'status': parcel.status,
      'createTime': parcel.createTime,
      'isDeleted': parcel.isDeleted,
      'syncStatus': parcel.syncStatus
    };

    try {
      const rowId = await this.rdbStore.insert(Constants.TABLE_NAME, valueBucket);
      return rowId;
    } catch (error) {
      console.error('Insert parcel failed:', JSON.stringify(error));
      return -1;
    }
  }

  /**
   * 查询所有未删除的包裹（按状态）
   */
  async queryParcelsByStatus(status: number): Promise<ParcelModel[]> {
    if (!this.rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.equalTo('status', status)
      .equalTo('isDeleted', Constants.NOT_DELETED)
      .orderByDesc('createTime');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      return this.convertResultSetToList(resultSet);
    } catch (error) {
      console.error('Query parcels failed:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 查询所有未删除的包裹
   */
  async queryAllParcels(): Promise<ParcelModel[]> {
    if (!this.rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.equalTo('isDeleted', Constants.NOT_DELETED)
      .orderByDesc('createTime');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      return this.convertResultSetToList(resultSet);
    } catch (error) {
      console.error('Query all parcels failed:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 按快递公司筛选
   */
  async queryParcelsByCompany(company: string, status: number): Promise<ParcelModel[]> {
    if (!this.rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.equalTo('courierCompany', company)
      .equalTo('status', status)
      .equalTo('isDeleted', Constants.NOT_DELETED)
      .orderByDesc('createTime');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      return this.convertResultSetToList(resultSet);
    } catch (error) {
      console.error('Query parcels by company failed:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 更新包裹状态
   */
  async updateParcelStatus(id: number, status: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'status': status
    };

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.equalTo('id', id);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      return rows > 0;
    } catch (error) {
      console.error('Update parcel status failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 软删除包裹
   */
  async deleteParcel(id: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'isDeleted': Constants.DELETED
    };

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.equalTo('id', id);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      return rows > 0;
    } catch (error) {
      console.error('Delete parcel failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 批量删除
   */
  async batchDeleteParcels(ids: number[]): Promise<boolean> {
    if (!this.rdbStore || ids.length === 0) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'isDeleted': Constants.DELETED
    };

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_NAME);
    predicates.in('id', ids);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      return rows > 0;
    } catch (error) {
      console.error('Batch delete parcels failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 添加或更新快递公司历史记录
   */
  async addOrUpdateCourierCompany(name: string): Promise<boolean> {
    if (!this.rdbStore || !name.trim()) {
      return false;
    }

    try {
      // 检查是否已存在
      const predicates = new relationalStore.RdbPredicates('courier_companies');
      predicates.equalTo('name', name);
      const resultSet = await this.rdbStore.query(predicates);

      if (resultSet.rowCount > 0) {
        // 已存在，更新使用次数和时间
        resultSet.goToFirstRow();
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const useCount = resultSet.getLong(resultSet.getColumnIndex('useCount'));
        resultSet.close();

        const valueBucket: relationalStore.ValuesBucket = {
          'useCount': useCount + 1,
          'lastUsedTime': Date.now()
        };
        const updatePredicates = new relationalStore.RdbPredicates('courier_companies');
        updatePredicates.equalTo('id', id);
        await this.rdbStore.update(valueBucket, updatePredicates);
      } else {
        // 不存在，插入新记录
        resultSet.close();
        const valueBucket: relationalStore.ValuesBucket = {
          'name': name,
          'useCount': 1,
          'lastUsedTime': Date.now(),
          'createTime': Date.now()
        };
        await this.rdbStore.insert('courier_companies', valueBucket);
      }
      return true;
    } catch (error) {
      console.error('Add/Update courier company failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取快递公司历史记录（按使用次数降序）
   */
  async queryCourierCompanies(): Promise<string[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('courier_companies');
      predicates.orderByDesc('useCount').orderByDesc('lastUsedTime');
      
      const resultSet = await this.rdbStore.query(predicates);
      const companies: string[] = [];

      if (resultSet.rowCount === 0) {
        resultSet.close();
        return companies;
      }

      resultSet.goToFirstRow();
      do {
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        companies.push(name);
      } while (resultSet.goToNextRow());

      resultSet.close();
      return companies;
    } catch (error) {
      console.error('Query courier companies failed:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 添加或更新驿站名称历史记录
   */
  async addOrUpdateStationName(name: string): Promise<boolean> {
    if (!this.rdbStore || !name.trim()) {
      return false;
    }

    try {
      // 检查是否已存在
      const predicates = new relationalStore.RdbPredicates('station_names');
      predicates.equalTo('name', name);
      const resultSet = await this.rdbStore.query(predicates);

      if (resultSet.rowCount > 0) {
        // 已存在，更新使用次数和时间
        resultSet.goToFirstRow();
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const useCount = resultSet.getLong(resultSet.getColumnIndex('useCount'));
        resultSet.close();

        const valueBucket: relationalStore.ValuesBucket = {
          'useCount': useCount + 1,
          'lastUsedTime': Date.now()
        };
        const updatePredicates = new relationalStore.RdbPredicates('station_names');
        updatePredicates.equalTo('id', id);
        await this.rdbStore.update(valueBucket, updatePredicates);
      } else {
        // 不存在，插入新记录
        resultSet.close();
        const valueBucket: relationalStore.ValuesBucket = {
          'name': name,
          'useCount': 1,
          'lastUsedTime': Date.now(),
          'createTime': Date.now()
        };
        await this.rdbStore.insert('station_names', valueBucket);
      }
      return true;
    } catch (error) {
      console.error('Add/Update station name failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取驿站名称历史记录（按使用次数降序）
   */
  async queryStationNames(): Promise<string[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('station_names');
      predicates.orderByDesc('useCount').orderByDesc('lastUsedTime');
      
      const resultSet = await this.rdbStore.query(predicates);
      const stations: string[] = [];

      if (resultSet.rowCount === 0) {
        resultSet.close();
        return stations;
      }

      resultSet.goToFirstRow();
      do {
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        stations.push(name);
      } while (resultSet.goToNextRow());

      resultSet.close();
      return stations;
    } catch (error) {
      console.error('Query station names failed:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 将结果集转换为列表
   */
  private convertResultSetToList(resultSet: relationalStore.ResultSet): ParcelModel[] {
    const parcels: ParcelModel[] = [];

    try {
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return parcels;
      }

      resultSet.goToFirstRow();
      do {
        const parcel = new ParcelModel(
          resultSet.getString(resultSet.getColumnIndex('pickupCode')),
          resultSet.getString(resultSet.getColumnIndex('courierCompany')),
          resultSet.getString(resultSet.getColumnIndex('stationName')),
          resultSet.getString(resultSet.getColumnIndex('address')),
          resultSet.getString(resultSet.getColumnIndex('pickupTime')),
          resultSet.getLong(resultSet.getColumnIndex('status'))
        );
        parcel.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        parcel.createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        parcel.isDeleted = resultSet.getLong(resultSet.getColumnIndex('isDeleted'));
        parcel.syncStatus = resultSet.getLong(resultSet.getColumnIndex('syncStatus'));

        parcels.push(parcel);
      } while (resultSet.goToNextRow());

      resultSet.close();
      return parcels;
    } catch (err) {
      console.error('Convert result set failed:', JSON.stringify(err));
      resultSet.close();
      return parcels;
    }
  }
}

