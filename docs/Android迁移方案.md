# 快递取件码管理 APP - Android 迁移方案

> **文档创建时间**: 2025-10-24  
> **基于版本**: HarmonyOS v1.0.0  
> **目标平台**: Android 13+ (API Level 33+)

---

## 📊 项目对比分析

### 技术栈对比

| 维度 | HarmonyOS (当前) | Android (目标) |
|------|-----------------|---------------|
| **开发语言** | ArkTS | Kotlin |
| **UI框架** | ArkUI (声明式) | Jetpack Compose (声明式) |
| **数据库** | RelationalStore | Room Database |
| **扫码功能** | ScanKit | ML Kit / ZXing |
| **权限管理** | abilityAccessCtrl | Android Permission System |
| **状态管理** | @State / @Prop | StateFlow / LiveData |
| **异步处理** | Promise / async-await | Coroutines / Flow |
| **依赖注入** | 手动注入 | Hilt / Koin |
| **架构模式** | 单体架构 | MVVM + Repository Pattern |

### 功能对比

| 功能模块 | HarmonyOS实现 | Android实现方案 | 难度 |
|---------|--------------|----------------|------|
| 数据库存储 | ✅ RelationalStore | ✅ Room | ⭐⭐ |
| 待取/已取列表 | ✅ 已实现 | ✅ LazyColumn | ⭐⭐ |
| 手动添加 | ✅ 已实现 | ✅ Compose Form | ⭐⭐ |
| 扫码识别 | ✅ ScanKit | ✅ ML Kit / ZXing | ⭐⭐⭐ |
| 短信监听 | ⚠️ 受限 | ✅ ContentObserver | ⭐⭐⭐⭐ |
| 侧滑删除 | ✅ swipeAction | ✅ SwipeToDismiss | ⭐⭐ |
| 状态切换 | ✅ 已实现 | ✅ Checkbox | ⭐ |
| 按公司排序 | ✅ 已实现 | ✅ sortedBy | ⭐⭐ |
| 一键清空 | ✅ 已实现 | ✅ AlertDialog | ⭐ |
| 剪贴板复制 | ✅ pasteboard | ✅ ClipboardManager | ⭐ |

---

## 🏗️ Android 项目架构

### 1. 技术栈选型

```kotlin
核心技术栈:
├── Kotlin 1.9+                    // 开发语言
├── Jetpack Compose               // 声明式UI框架
├── Material Design 3             // UI设计规范
├── Room Database                 // 本地数据库
├── ViewModel + StateFlow         // 状态管理
├── Kotlin Coroutines + Flow      // 异步处理
├── Hilt                          // 依赖注入
├── ML Kit Barcode Scanning       // 扫码功能
├── CameraX                       // 相机集成
└── Navigation Compose            // 页面导航
```

### 2. 项目结构

```
app/src/main/java/com/pickcode/
│
├── data/                         # 数据层
│   ├── local/                    # 本地数据源
│   │   ├── ParcelDatabase.kt     # Room数据库
│   │   ├── ParcelDao.kt          # 数据访问对象
│   │   └── entity/
│   │       └── ParcelEntity.kt   # 数据实体
│   │
│   ├── repository/               # 数据仓库
│   │   └── ParcelRepository.kt   # 统一数据访问接口
│   │
│   └── model/                    # 数据模型
│       ├── Parcel.kt             # 业务模型
│       ├── CourierCompany.kt     # 快递公司
│       └── ParcelStatus.kt       # 包裹状态枚举
│
├── ui/                           # UI层
│   ├── home/                     # 主页面
│   │   ├── HomeScreen.kt         # 主页面UI
│   │   └── HomeViewModel.kt      # 主页面ViewModel
│   │
│   ├── add/                      # 添加页面
│   │   ├── AddParcelScreen.kt    # 添加页面UI
│   │   └── AddParcelViewModel.kt # 添加页面ViewModel
│   │
│   ├── scan/                     # 扫码页面
│   │   ├── ScanScreen.kt         # 扫码UI
│   │   └── ScanViewModel.kt      # 扫码ViewModel
│   │
│   ├── components/               # 可复用组件
│   │   ├── ParcelCard.kt         # 快递卡片
│   │   ├── ParcelListItem.kt     # 列表项
│   │   ├── CourierIcon.kt        # 快递图标
│   │   ├── FilterBar.kt          # 筛选栏
│   │   ├── DateHeader.kt         # 日期分组头
│   │   ├── BottomTabBar.kt       # 底部TAB
│   │   └── TopBar.kt             # 顶部栏
│   │
│   ├── theme/                    # 主题配置
│   │   ├── Color.kt              # 颜色定义
│   │   ├── Type.kt               # 字体定义
│   │   └── Theme.kt              # 主题配置
│   │
│   └── navigation/               # 导航配置
│       └── NavGraph.kt           # 导航图
│
├── service/                      # 业务服务层
│   ├── ScanService.kt            # 扫码服务
│   ├── SmsService.kt             # 短信监听服务
│   ├── ParserService.kt          # 快递单解析服务
│   └── ClipboardService.kt       # 剪贴板服务
│
├── util/                         # 工具类
│   ├── Constants.kt              # 常量配置
│   ├── DateUtils.kt              # 日期工具
│   ├── PermissionHelper.kt       # 权限工具
│   └── Extensions.kt             # Kotlin扩展函数
│
├── di/                           # 依赖注入模块
│   ├── DatabaseModule.kt         # 数据库模块
│   ├── RepositoryModule.kt       # 仓库模块
│   └── ServiceModule.kt          # 服务模块
│
└── MainActivity.kt               # 主Activity
```

---

## 💾 核心代码实现

### 1. 数据模型层

#### 1.1 Room Entity (数据库实体)

```kotlin
// data/local/entity/ParcelEntity.kt
package com.pickcode.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "parcel_records")
data class ParcelEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    
    @ColumnInfo(name = "pickup_code")
    val pickupCode: String,
    
    @ColumnInfo(name = "courier_company")
    val courierCompany: String,
    
    @ColumnInfo(name = "station_name")
    val stationName: String,
    
    @ColumnInfo(name = "address")
    val address: String,
    
    @ColumnInfo(name = "pickup_time")
    val pickupTime: String,
    
    @ColumnInfo(name = "status")
    val status: Int, // 0-待取, 1-已取
    
    @ColumnInfo(name = "create_time")
    val createTime: Long = System.currentTimeMillis(),
    
    @ColumnInfo(name = "is_deleted")
    val isDeleted: Boolean = false,
    
    @ColumnInfo(name = "sync_status")
    val syncStatus: Int = 0 // 0-未同步, 1-已同步
)
```

#### 1.2 业务模型

```kotlin
// data/model/Parcel.kt
package com.pickcode.data.model

data class Parcel(
    val id: Long = 0,
    val pickupCode: String,
    val courierCompany: String,
    val stationName: String,
    val address: String,
    val pickupTime: String,
    val status: ParcelStatus,
    val createTime: Long = System.currentTimeMillis()
)

enum class ParcelStatus {
    PENDING,  // 待取
    PICKED    // 已取
}

// data/model/CourierCompany.kt
data class CourierCompany(
    val name: String,
    val keyword: String,
    val iconResId: Int
)

// 扩展函数：Entity <-> Model 转换
fun ParcelEntity.toParcel(): Parcel {
    return Parcel(
        id = id,
        pickupCode = pickupCode,
        courierCompany = courierCompany,
        stationName = stationName,
        address = address,
        pickupTime = pickupTime,
        status = if (status == 0) ParcelStatus.PENDING else ParcelStatus.PICKED,
        createTime = createTime
    )
}

fun Parcel.toEntity(): ParcelEntity {
    return ParcelEntity(
        id = id,
        pickupCode = pickupCode,
        courierCompany = courierCompany,
        stationName = stationName,
        address = address,
        pickupTime = pickupTime,
        status = if (status == ParcelStatus.PENDING) 0 else 1,
        createTime = createTime
    )
}
```

### 2. 数据库层 (Room)

#### 2.1 DAO (数据访问对象)

```kotlin
// data/local/ParcelDao.kt
package com.pickcode.data.local

import androidx.room.*
import com.pickcode.data.local.entity.ParcelEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ParcelDao {
    
    // 查询所有待取包裹
    @Query("SELECT * FROM parcel_records WHERE is_deleted = 0 AND status = 0 ORDER BY create_time DESC")
    fun getPendingParcels(): Flow<List<ParcelEntity>>
    
    // 查询所有已取包裹
    @Query("SELECT * FROM parcel_records WHERE is_deleted = 0 AND status = 1 ORDER BY create_time DESC")
    fun getPickedParcels(): Flow<List<ParcelEntity>>
    
    // 根据状态查询
    @Query("SELECT * FROM parcel_records WHERE is_deleted = 0 AND status = :status ORDER BY create_time DESC")
    fun getParcelsByStatus(status: Int): Flow<List<ParcelEntity>>
    
    // 插入包裹
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(parcel: ParcelEntity): Long
    
    // 批量插入
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(parcels: List<ParcelEntity>)
    
    // 更新包裹
    @Update
    suspend fun update(parcel: ParcelEntity)
    
    // 更新包裹状态
    @Query("UPDATE parcel_records SET status = :status WHERE id = :id")
    suspend fun updateStatus(id: Long, status: Int)
    
    // 批量更新状态
    @Query("UPDATE parcel_records SET status = :status WHERE id IN (:ids)")
    suspend fun batchUpdateStatus(ids: List<Long>, status: Int)
    
    // 删除包裹（软删除）
    @Query("UPDATE parcel_records SET is_deleted = 1 WHERE id = :id")
    suspend fun softDelete(id: Long)
    
    // 物理删除
    @Delete
    suspend fun delete(parcel: ParcelEntity)
    
    // 批量删除
    @Query("DELETE FROM parcel_records WHERE id IN (:ids)")
    suspend fun batchDelete(ids: List<Long>)
    
    // 清空所有已取
    @Query("DELETE FROM parcel_records WHERE status = 1")
    suspend fun clearAllPicked()
    
    // 根据ID查询
    @Query("SELECT * FROM parcel_records WHERE id = :id")
    suspend fun getParcelById(id: Long): ParcelEntity?
    
    // 统计数量
    @Query("SELECT COUNT(*) FROM parcel_records WHERE is_deleted = 0 AND status = :status")
    fun getCountByStatus(status: Int): Flow<Int>
}
```

#### 2.2 Database 配置

```kotlin
// data/local/ParcelDatabase.kt
package com.pickcode.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.pickcode.data.local.entity.ParcelEntity

@Database(
    entities = [ParcelEntity::class],
    version = 1,
    exportSchema = false
)
abstract class ParcelDatabase : RoomDatabase() {
    
    abstract fun parcelDao(): ParcelDao
    
    companion object {
        @Volatile
        private var INSTANCE: ParcelDatabase? = null
        
        fun getDatabase(context: Context): ParcelDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    ParcelDatabase::class.java,
                    "parcel_database"
                )
                    .fallbackToDestructiveMigration() // 开发阶段使用，生产环境需要迁移策略
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
```

### 3. Repository 层

```kotlin
// data/repository/ParcelRepository.kt
package com.pickcode.data.repository

import com.pickcode.data.local.ParcelDao
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus
import com.pickcode.data.model.toEntity
import com.pickcode.data.model.toParcel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ParcelRepository @Inject constructor(
    private val parcelDao: ParcelDao
) {
    
    // 获取待取包裹列表
    fun getPendingParcels(): Flow<List<Parcel>> =
        parcelDao.getPendingParcels().map { entities ->
            entities.map { it.toParcel() }
        }
    
    // 获取已取包裹列表
    fun getPickedParcels(): Flow<List<Parcel>> =
        parcelDao.getPickedParcels().map { entities ->
            entities.map { it.toParcel() }
        }
    
    // 根据状态获取包裹
    fun getParcelsByStatus(status: ParcelStatus): Flow<List<Parcel>> =
        parcelDao.getParcelsByStatus(
            if (status == ParcelStatus.PENDING) 0 else 1
        ).map { entities ->
            entities.map { it.toParcel() }
        }
    
    // 添加包裹
    suspend fun addParcel(parcel: Parcel): Long {
        return parcelDao.insert(parcel.toEntity())
    }
    
    // 更新包裹
    suspend fun updateParcel(parcel: Parcel) {
        parcelDao.update(parcel.toEntity())
    }
    
    // 切换包裹状态
    suspend fun updateParcelStatus(id: Long, status: ParcelStatus) {
        parcelDao.updateStatus(id, if (status == ParcelStatus.PENDING) 0 else 1)
    }
    
    // 批量更新状态
    suspend fun batchUpdateStatus(ids: List<Long>, status: ParcelStatus) {
        parcelDao.batchUpdateStatus(ids, if (status == ParcelStatus.PENDING) 0 else 1)
    }
    
    // 删除单个包裹
    suspend fun deleteParcel(id: Long) {
        parcelDao.batchDelete(listOf(id))
    }
    
    // 批量删除
    suspend fun batchDelete(ids: List<Long>) {
        parcelDao.batchDelete(ids)
    }
    
    // 清空所有已取
    suspend fun clearAllPicked() {
        parcelDao.clearAllPicked()
    }
    
    // 获取包裹数量
    fun getPendingCount(): Flow<Int> = parcelDao.getCountByStatus(0)
    fun getPickedCount(): Flow<Int> = parcelDao.getCountByStatus(1)
}
```

### 4. ViewModel 层 (MVVM)

```kotlin
// ui/home/HomeViewModel.kt
package com.pickcode.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus
import com.pickcode.data.repository.ParcelRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: ParcelRepository
) : ViewModel() {
    
    // 当前选中的TAB: 0-待取, 1-已取
    private val _currentTab = MutableStateFlow(0)
    val currentTab: StateFlow<Int> = _currentTab.asStateFlow()
    
    // 排序模式
    private val _sortMode = MutableStateFlow(SortMode.BY_TIME)
    val sortMode: StateFlow<SortMode> = _sortMode.asStateFlow()
    
    // 快递公司排序顺序（用于保持排序稳定性）
    private val _companySortOrder = MutableStateFlow<List<String>>(emptyList())
    
    // 编辑模式
    private val _isEditMode = MutableStateFlow(false)
    val isEditMode: StateFlow<Boolean> = _isEditMode.asStateFlow()
    
    // 选中的包裹ID集合
    private val _selectedParcels = MutableStateFlow<Set<Long>>(emptySet())
    val selectedParcels: StateFlow<Set<Long>> = _selectedParcels.asStateFlow()
    
    // 包裹列表（根据当前TAB动态切换）
    val parcels: StateFlow<List<Parcel>> = currentTab.flatMapLatest { tab ->
        if (tab == 0) repository.getPendingParcels()
        else repository.getPickedParcels()
    }.combine(sortMode) { parcels, mode ->
        sortParcels(parcels, mode)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    
    // 包裹数量
    val pendingCount: StateFlow<Int> = repository.getPendingCount()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)
    
    val pickedCount: StateFlow<Int> = repository.getPickedCount()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)
    
    // 切换TAB
    fun switchTab(index: Int) {
        _currentTab.value = index
        _isEditMode.value = false
        _selectedParcels.value = emptySet()
        _companySortOrder.value = emptyList() // 清空排序顺序
    }
    
    // 设置排序模式
    fun setSortMode(mode: SortMode) {
        _sortMode.value = mode
        if (mode == SortMode.BY_COMPANY) {
            // 切换到按公司排序时重新计算顺序
            _companySortOrder.value = emptyList()
        }
    }
    
    // 包裹排序
    private fun sortParcels(parcels: List<Parcel>, mode: SortMode): List<Parcel> {
        return when (mode) {
            SortMode.BY_TIME -> parcels.sortedByDescending { it.createTime }
            SortMode.BY_COMPANY -> sortByCompanyCount(parcels)
        }
    }
    
    // 按快递公司数量排序
    private fun sortByCompanyCount(parcels: List<Parcel>): List<Parcel> {
        // 按公司分组
        val companyGroups = parcels.groupBy { it.courierCompany }
        
        // 每个公司内部按时间排序
        val sortedGroups = companyGroups.mapValues { (_, parcels) ->
            parcels.sortedByDescending { it.createTime }
        }
        
        // 确定公司顺序
        val sortedCompanies = if (_companySortOrder.value.isEmpty()) {
            // 首次排序：按包裹数量排序
            companyGroups.keys.sortedByDescending { companyGroups[it]?.size ?: 0 }
                .also { _companySortOrder.value = it }
        } else {
            // 使用保存的顺序，过滤掉已删除的公司
            val currentCompanies = companyGroups.keys
            _companySortOrder.value.filter { it in currentCompanies } +
                currentCompanies.filter { it !in _companySortOrder.value }
        }
        
        // 按公司顺序展开
        return sortedCompanies.flatMap { company ->
            sortedGroups[company] ?: emptyList()
        }
    }
    
    // 切换包裹状态
    fun toggleParcelStatus(parcel: Parcel) {
        viewModelScope.launch {
            val newStatus = if (parcel.status == ParcelStatus.PENDING) {
                ParcelStatus.PICKED
            } else {
                ParcelStatus.PENDING
            }
            repository.updateParcelStatus(parcel.id, newStatus)
        }
    }
    
    // 删除单个包裹
    fun deleteParcel(id: Long) {
        viewModelScope.launch {
            repository.deleteParcel(id)
        }
    }
    
    // 切换编辑模式
    fun toggleEditMode() {
        _isEditMode.value = !_isEditMode.value
        if (!_isEditMode.value) {
            _selectedParcels.value = emptySet()
        }
    }
    
    // 切换包裹选中状态
    fun toggleParcelSelection(id: Long) {
        _selectedParcels.value = if (id in _selectedParcels.value) {
            _selectedParcels.value - id
        } else {
            _selectedParcels.value + id
        }
    }
    
    // 批量删除选中的包裹
    fun deleteSelectedParcels() {
        viewModelScope.launch {
            repository.batchDelete(_selectedParcels.value.toList())
            _selectedParcels.value = emptySet()
            _isEditMode.value = false
        }
    }
    
    // 清空所有已取
    fun clearAllPicked() {
        viewModelScope.launch {
            repository.clearAllPicked()
        }
    }
}

enum class SortMode {
    BY_TIME,      // 按时间排序
    BY_COMPANY    // 按快递公司排序
}
```

```kotlin
// ui/add/AddParcelViewModel.kt
package com.pickcode.ui.add

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus
import com.pickcode.data.repository.ParcelRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AddParcelViewModel @Inject constructor(
    private val repository: ParcelRepository
) : ViewModel() {
    
    private val _pickupCode = MutableStateFlow("")
    val pickupCode: StateFlow<String> = _pickupCode.asStateFlow()
    
    private val _courierCompany = MutableStateFlow("")
    val courierCompany: StateFlow<String> = _courierCompany.asStateFlow()
    
    private val _stationName = MutableStateFlow("")
    val stationName: StateFlow<String> = _stationName.asStateFlow()
    
    private val _address = MutableStateFlow("")
    val address: StateFlow<String> = _address.asStateFlow()
    
    private val _pickupTime = MutableStateFlow("")
    val pickupTime: StateFlow<String> = _pickupTime.asStateFlow()
    
    fun updatePickupCode(value: String) { _pickupCode.value = value }
    fun updateCourierCompany(value: String) { _courierCompany.value = value }
    fun updateStationName(value: String) { _stationName.value = value }
    fun updateAddress(value: String) { _address.value = value }
    fun updatePickupTime(value: String) { _pickupTime.value = value }
    
    // 保存包裹
    fun saveParcel(onSuccess: () -> Unit, onError: (String) -> Unit) {
        if (!validateInput()) {
            onError("请填写必填项")
            return
        }
        
        viewModelScope.launch {
            try {
                val parcel = Parcel(
                    pickupCode = _pickupCode.value,
                    courierCompany = _courierCompany.value,
                    stationName = _stationName.value,
                    address = _address.value,
                    pickupTime = _pickupTime.value,
                    status = ParcelStatus.PENDING
                )
                repository.addParcel(parcel)
                onSuccess()
            } catch (e: Exception) {
                onError(e.message ?: "保存失败")
            }
        }
    }
    
    // 从扫码结果填充数据
    fun fillFromScanResult(parcel: Parcel) {
        _pickupCode.value = parcel.pickupCode
        _courierCompany.value = parcel.courierCompany
        _stationName.value = parcel.stationName
        _address.value = parcel.address
        _pickupTime.value = parcel.pickupTime
    }
    
    private fun validateInput(): Boolean {
        return _pickupCode.value.isNotBlank() && _courierCompany.value.isNotBlank()
    }
}
```

### 5. Jetpack Compose UI 层

#### 5.1 主页面

```kotlin
// ui/home/HomeScreen.kt
package com.pickcode.ui.home

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.pickcode.ui.components.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel(),
    onAddClick: () -> Unit,
    onScanClick: () -> Unit
) {
    val currentTab by viewModel.currentTab.collectAsState()
    val parcels by viewModel.parcels.collectAsState()
    val sortMode by viewModel.sortMode.collectAsState()
    val isEditMode by viewModel.isEditMode.collectAsState()
    val selectedParcels by viewModel.selectedParcels.collectAsState()
    val pendingCount by viewModel.pendingCount.collectAsState()
    
    // 显示清空确认对话框
    var showClearDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopBar(
                title = if (currentTab == 0) "待取包裹 ($pendingCount)" else "取件记录",
                currentTab = currentTab,
                isEditMode = isEditMode,
                onAddClick = onAddClick,
                onScanClick = onScanClick,
                onImportClick = { /* 导入功能 */ },
                onEditClick = { viewModel.toggleEditMode() },
                onClearClick = { showClearDialog = true }
            )
        },
        bottomBar = {
            BottomTabBar(
                currentTab = currentTab,
                onTabChange = { viewModel.switchTab(it) }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 待取TAB显示筛选栏
            if (currentTab == 0) {
                FilterBar(
                    selectedMode = sortMode,
                    onModeChange = { viewModel.setSortMode(it) }
                )
            }
            
            // 包裹列表
            ParcelList(
                parcels = parcels,
                sortMode = sortMode,
                isEditMode = isEditMode,
                selectedParcels = selectedParcels,
                onStatusToggle = { viewModel.toggleParcelStatus(it) },
                onDelete = { viewModel.deleteParcel(it.id) },
                onSelectionToggle = { viewModel.toggleParcelSelection(it) }
            )
            
            // 编辑模式底部操作栏
            if (isEditMode && selectedParcels.isNotEmpty()) {
                BottomActionBar(
                    selectedCount = selectedParcels.size,
                    onDeleteClick = { viewModel.deleteSelectedParcels() }
                )
            }
        }
    }
    
    // 清空确认对话框
    if (showClearDialog) {
        AlertDialog(
            onDismissRequest = { showClearDialog = false },
            title = { Text("确认清空") },
            text = { Text("确定要清空所有已取的记录吗？共 ${parcels.size} 条记录将被删除。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.clearAllPicked()
                        showClearDialog = false
                    }
                ) {
                    Text("确定", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}
```

#### 5.2 包裹卡片组件

```kotlin
// ui/components/ParcelCard.kt
package com.pickcode.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParcelCard(
    parcel: Parcel,
    onStatusToggle: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val clipboardManager = LocalClipboardManager.current
    val dismissState = rememberDismissState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == DismissValue.DismissedToStart) {
                onDelete()
                true
            } else {
                false
            }
        }
    )
    
    SwipeToDismiss(
        state = dismissState,
        background = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.error)
                    .padding(horizontal = 24.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                Text(
                    text = "删除",
                    color = Color.White,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        dismissContent = {
            Card(
                modifier = modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                colors = CardDefaults.cardColors(
                    containerColor = Color.White
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // 状态勾选框
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .clip(CircleShape)
                            .background(
                                if (parcel.status == ParcelStatus.PICKED)
                                    MaterialTheme.colorScheme.primary
                                else Color.Transparent
                            )
                            .border(
                                width = if (parcel.status == ParcelStatus.PENDING) 2.dp else 0.dp,
                                color = Color(0xFFDDDDDD),
                                shape = CircleShape
                            )
                            .clickable { onStatusToggle() },
                        contentAlignment = Alignment.Center
                    ) {
                        if (parcel.status == ParcelStatus.PICKED) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "已取",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    // 快递公司图标
                    CourierIcon(
                        company = parcel.courierCompany,
                        size = 48.dp
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    // 信息列
                    Column(modifier = Modifier.weight(1f)) {
                        // 快递公司名称
                        Text(
                            text = parcel.courierCompany,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.Black
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        // 取件码（可点击复制）
                        Text(
                            text = parcel.pickupCode,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.Black,
                            modifier = Modifier.clickable {
                                clipboardManager.setText(AnnotatedString(parcel.pickupCode))
                                // TODO: 显示Toast提示
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        // 驿站名称
                        Text(
                            text = parcel.stationName,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF999999)
                        )
                    }
                }
            }
        },
        directions = setOf(DismissDirection.EndToStart)
    )
}
```

### 6. 扫码服务

```kotlin
// service/ScanService.kt
package com.pickcode.service

import android.content.Context
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus
import com.pickcode.util.Constants
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ScanService @Inject constructor(
    private val context: Context
) {
    private val scanner = BarcodeScanning.getClient()
    
    // 处理图片并识别条形码
    suspend fun scanImage(inputImage: InputImage): List<Barcode> {
        return try {
            scanner.process(inputImage).await()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    // 解析条形码内容为包裹信息
    fun parseBarcode(content: String): Parcel? {
        // 识别快递公司
        val company = identifyCourier(content)
        
        // 提取取件码
        val pickupCode = extractPickupCode(content)
        
        // 提取驿站信息
        val stationInfo = extractStationInfo(content)
        
        return if (pickupCode.isNotEmpty()) {
            Parcel(
                pickupCode = pickupCode,
                courierCompany = company,
                stationName = stationInfo.first,
                address = stationInfo.second,
                pickupTime = "",
                status = ParcelStatus.PENDING
            )
        } else {
            null
        }
    }
    
    // 识别快递公司
    private fun identifyCourier(content: String): String {
        Constants.COURIER_COMPANIES.forEach { company ->
            if (content.contains(Regex(company.keyword, RegexOption.IGNORE_CASE))) {
                return company.name
            }
        }
        return "未知快递"
    }
    
    // 提取取件码
    private fun extractPickupCode(content: String): String {
        val patterns = listOf(
            Regex("取件码[：:：\\s]*([0-9A-Za-z]{4,8})"),
            Regex("提货码[：:：\\s]*([0-9A-Za-z]{4,8})"),
            Regex("验证码[：:：\\s]*([0-9A-Za-z]{4,8})"),
            Regex("取货码[：:：\\s]*([0-9A-Za-z]{4,8})"),
            Regex("code[：:：\\s]*([0-9A-Za-z]{4,8})", RegexOption.IGNORE_CASE)
        )
        
        patterns.forEach { pattern ->
            pattern.find(content)?.let {
                return it.groupValues[1]
            }
        }
        
        return ""
    }
    
    // 提取驿站信息
    private fun extractStationInfo(content: String): Pair<String, String> {
        var stationName = "驿站"
        var address = ""
        
        // 提取驿站名称
        val stationPatterns = listOf(
            Regex("(菜鸟驿站[^\\n]*)"),
            Regex("(兔喜生活[^\\n]*)"),
            Regex("(妈妈驿站[^\\n]*)"),
            Regex("(驿站[^\\n]*)")
        )
        
        stationPatterns.forEach { pattern ->
            pattern.find(content)?.let {
                stationName = it.groupValues[1].take(20)
                return@forEach
            }
        }
        
        // 提取地址
        val addressPattern = Regex("地址[：:：\\s]*([^\\n]{10,50})")
        addressPattern.find(content)?.let {
            address = it.groupValues[1]
        }
        
        return Pair(stationName, address.ifEmpty { "请手动补充地址" })
    }
}
```

### 7. 短信监听服务

```kotlin
// service/SmsService.kt
package com.pickcode.service

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import com.pickcode.data.model.Parcel
import com.pickcode.data.model.ParcelStatus
import com.pickcode.data.repository.ParcelRepository
import com.pickcode.util.Constants
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SmsService @Inject constructor(
    private val context: Context,
    private val repository: ParcelRepository,
    private val scanService: ScanService
) {
    
    private val coroutineScope = CoroutineScope(Dispatchers.IO)
    
    private val smsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            super.onChange(selfChange)
            readLatestSms()
        }
    }
    
    // 开始监听短信
    fun startListening() {
        context.contentResolver.registerContentObserver(
            Telephony.Sms.CONTENT_URI,
            true,
            smsObserver
        )
    }
    
    // 停止监听短信
    fun stopListening() {
        context.contentResolver.unregisterContentObserver(smsObserver)
    }
    
    // 读取最新短信
    private fun readLatestSms() {
        try {
            val cursor = context.contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf(
                    Telephony.Sms.ADDRESS,
                    Telephony.Sms.BODY,
                    Telephony.Sms.DATE
                ),
                null,
                null,
                "${Telephony.Sms.DATE} DESC LIMIT 1"
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                    val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                    
                    // 检查是否为快递短信
                    if (isExpressSms(body)) {
                        parseAndSaveSms(body)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    // 判断是否为快递短信
    private fun isExpressSms(body: String): Boolean {
        val keywords = listOf("取件码", "提货码", "验证码", "快递", "驿站", "菜鸟", "兔喜", "妈妈")
        return keywords.any { body.contains(it) }
    }
    
    // 解析短信并保存
    private fun parseAndSaveSms(body: String) {
        scanService.parseBarcode(body)?.let { parcel ->
            coroutineScope.launch {
                try {
                    repository.addParcel(parcel)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    // 手动读取所有快递短信
    suspend fun importAllExpressSms(): Int {
        var importCount = 0
        try {
            val cursor = context.contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf(Telephony.Sms.BODY, Telephony.Sms.DATE),
                null,
                null,
                "${Telephony.Sms.DATE} DESC LIMIT 100"
            )
            
            cursor?.use {
                while (it.moveToNext()) {
                    val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                    if (isExpressSms(body)) {
                        scanService.parseBarcode(body)?.let { parcel ->
                            repository.addParcel(parcel)
                            importCount++
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return importCount
    }
}
```

### 8. 常量配置

```kotlin
// util/Constants.kt
package com.pickcode.util

import com.pickcode.R
import com.pickcode.data.model.CourierCompany

object Constants {
    
    // 快递公司配置（按业务量排序）
    val COURIER_COMPANIES = listOf(
        CourierCompany("顺丰速运", "顺丰|SF|sf", R.drawable.ic_shunfeng),
        CourierCompany("中通快递", "中通|ZTO|zto", R.drawable.ic_zhongtong),
        CourierCompany("申通快递", "申通|STO|sto", R.drawable.ic_shentong),
        CourierCompany("韵达快递", "韵达|YUNDA|yunda", R.drawable.ic_yunda),
        CourierCompany("极兔速递", "极兔|J&T|JT|jt", R.drawable.ic_jtexpress),
        CourierCompany("邮政快递", "邮政|EMS|ems|中国邮政", R.drawable.ic_youzheng),
        CourierCompany("圆通速递", "圆通|YTO|yto", R.drawable.ic_yuantong),
        CourierCompany("京东快递", "京东|JD|jd", R.drawable.ic_jd),
        CourierCompany("百世快递", "百世|BEST|best|百世快运", R.drawable.ic_baishi),
        CourierCompany("德邦快递", "德邦|DEPPON|deppon", R.drawable.ic_debang),
        CourierCompany("安能物流", "安能|ANNENG|anneng", R.drawable.ic_anneng),
        CourierCompany("天天快递", "天天|TTKD|ttkd", R.drawable.ic_tiantian),
        CourierCompany("宅急送", "宅急送|ZJS|zjs", R.drawable.ic_zhaijisong),
        CourierCompany("菜鸟驿站", "菜鸟|cainiao", R.drawable.ic_cainiao),
        CourierCompany("妈妈驿站", "妈妈驿站|妈妈", R.drawable.ic_mama),
        CourierCompany("兔喜生活", "兔喜|免喜|兔喜生活", R.drawable.ic_tuxi)
    )
    
    // 颜色配置（与HarmonyOS版本保持一致）
    object Colors {
        const val PRIMARY = 0xFF000000
        const val ACCENT = 0xFF007AFF
        const val BACKGROUND = 0xFFF5F5F5
        const val CARD_BG = 0xFFFFFFFF
        const val SECONDARY_TEXT = 0xFF999999
        const val DIVIDER = 0xFFDDDDDD
    }
    
    // UI尺寸
    object Size {
        const val CARD_BORDER_RADIUS = 16
        const val ICON_SIZE = 48
        const val PADDING_NORMAL = 16
        const val PADDING_SMALL = 12
        const val PADDING_LARGE = 20
    }
}
```

---

## 📦 依赖配置

### build.gradle.kts (Project level)

```kotlin
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("com.android.library") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
    id("com.google.dagger.hilt.android") version "2.48" apply false
    id("com.google.devtools.ksp") version "1.9.20-1.0.14" apply false
}
```

### build.gradle.kts (Module :app)

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.devtools.ksp")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.pickcode"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.pickcode"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    buildFeatures {
        compose = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
    
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Jetpack Compose
    implementation("androidx.compose.ui:ui:1.5.4")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.compose.ui:ui-tooling-preview:1.5.4")
    implementation("androidx.activity:activity-compose:1.8.1")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    debugImplementation("androidx.compose.ui:ui-tooling:1.5.4")
    
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    
    // Room Database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")
    
    // ViewModel & LiveData
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.6.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // Hilt (依赖注入)
    implementation("com.google.dagger:hilt-android:2.48")
    ksp("com.google.dagger:hilt-compiler:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    
    // ML Kit Barcode Scanning (扫码)
    implementation("com.google.mlkit:barcode-scanning:17.2.0")
    
    // CameraX (相机)
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    
    // ZXing (备选扫码方案)
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
    implementation("com.google.zxing:core:3.5.2")
    
    // Coil (图片加载)
    implementation("io.coil-kt:coil-compose:2.5.0")
    
    // Accompanist (Compose扩展)
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")
    implementation("com.google.accompanist:accompanist-systemuicontroller:0.32.0")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.5.4")
}
```

---

## 🔐 权限配置

### AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <!-- 相机权限 -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature
        android:name="android.hardware.camera"
        android:required="false" />
    
    <!-- 短信权限 -->
    <uses-permission android:name="android.permission.READ_SMS" />
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
    
    <!-- 网络权限(预留云同步) -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- 存储权限(导入导出) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"
        tools:ignore="ScopedStorage" />
    
    <application
        android:name=".PickCodeApplication"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.PickCode"
        tools:targetApi="31">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.PickCode">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <!-- 扫码Activity -->
        <activity
            android:name="com.journeyapps.barcodescanner.CaptureActivity"
            android:screenOrientation="portrait"
            tools:replace="screenOrientation" />
    </application>
    
</manifest>
```

---

## ✨ Android 特有优势

相比HarmonyOS版本，Android版本具有以下优势：

### 1. 短信功能更完善
- ✅ **ContentObserver** - Android原生支持短信监听，更稳定
- ✅ **后台监听** - 可以实现真正的后台短信监听（需要权限）
- ✅ **批量导入** - 可以一次性读取历史短信导入所有快递信息

### 2. 扫码库更成熟
- ✅ **ML Kit** - Google官方扫码库，识别率高
- ✅ **ZXing** - 开源成熟方案，支持离线识别
- ✅ **相册选择** - 支持从相册选择图片识别

### 3. 生态更完善
- ✅ **海量第三方库** - UI组件、工具库应有尽有
- ✅ **社区活跃** - 遇到问题可快速找到解决方案
- ✅ **开发工具成熟** - Android Studio功能强大

### 4. 适配设备更多
- ✅ **覆盖面广** - 几乎所有Android手机都能运行
- ✅ **版本兼容性好** - 支持Android 8.0+（API 26+）
- ✅ **平板适配** - 天然支持大屏设备

### 5. 调试更方便
- ✅ **实时预览** - Jetpack Compose Preview可实时查看UI
- ✅ **Layout Inspector** - 强大的UI调试工具
- ✅ **Profiler** - 性能分析工具完善

---

## 🚀 实施方案

### 方案A：完整迁移（推荐）

**优点**：
- 完整的Android原生体验
- 充分利用Android生态优势
- 独立开发，不受HarmonyOS限制

**实施步骤**：
1. 创建Android项目基础架构（1天）
2. 实现数据库和Repository层（1天）
3. 实现UI层（主页+添加页）（2天）
4. 实现扫码功能（1天）
5. 实现短信监听功能（1天）
6. UI优化和测试（2天）

**预计时间**：8个工作日

---

### 方案B：关键模块迁移

先实现核心功能，其他功能逐步添加。

**Phase 1 - MVP（最小可行产品）**：
- ✅ 数据库存储
- ✅ 手动添加/删除
- ✅ 待取/已取列表
- ✅ 状态切换

**Phase 2 - 扩展功能**：
- ✅ 扫码识别
- ✅ 按公司排序
- ✅ 侧滑删除

**Phase 3 - 高级功能**：
- ✅ 短信监听
- ✅ 批量操作
- ✅ 数据导出

**预计时间**：分3个阶段，每阶段3-5天

---

### 方案C：混合方案

保留HarmonyOS版本，Android版本作为补充，共享后端API。

**适用场景**：
- 需要同时维护两个平台
- 有云端数据同步需求
- 用户群体横跨两个平台

**架构**：
```
HarmonyOS App ──┐
                ├──> 云端API服务 ──> 数据库
Android App ────┘
```

---

## 📝 开发建议

### 1. 代码规范
- 使用Kotlin官方代码风格
- 遵循MVVM架构模式
- 使用Jetpack Compose声明式UI
- 充分利用Kotlin协程处理异步

### 2. 性能优化
- 使用LazyColumn替代RecyclerView
- 合理使用remember和derivedStateOf
- 避免过度重组（recomposition）
- 使用Flow替代LiveData

### 3. 测试策略
- 单元测试：ViewModel和Repository
- UI测试：使用Compose Testing
- 集成测试：数据库操作

### 4. 发布准备
- 混淆配置（ProGuard/R8）
- 签名配置
- 多渠道打包
- Google Play上架准备

---

## 🔄 后续扩展功能

### 1. 云端同步
```kotlin
// 使用Firebase或自建服务器
- Firebase Realtime Database
- Firebase Authentication
- 多设备数据同步
```

### 2. 通知提醒
```kotlin
// 取件提醒功能
- WorkManager定时检查
- 本地通知推送
- 超时未取提醒
```

### 3. 数据统计
```kotlin
// 可视化数据分析
- 每月取件量统计
- 快递公司占比
- 取件时效分析
```

### 4. Widget支持
```kotlin
// 桌面小部件
- 显示待取数量
- 快捷添加入口
- Glance API实现
```

---

## 📚 参考资料

### 官方文档
- [Jetpack Compose 官方文档](https://developer.android.com/jetpack/compose)
- [Room Database 指南](https://developer.android.com/training/data-storage/room)
- [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [Android 权限最佳实践](https://developer.android.com/training/permissions/requesting)

### 开源项目参考
- [Now in Android](https://github.com/android/nowinandroid) - Google官方示例
- [Tivi](https://github.com/chrisbanes/tivi) - Compose最佳实践
- [JetChat](https://github.com/android/compose-samples) - Compose样例

---

## 📞 联系方式

如有问题或建议，欢迎反馈！

---

**文档版本**: v1.0  
**最后更新**: 2025-10-24  
**状态**: 📝 待实施

