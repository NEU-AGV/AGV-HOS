// /entry/src/main/ets/pages/DefectListPage.ets

import router from '@ohos.router';
import { Defect } from '../model/Defect';
import DefectService from '../services/ApiService';

// 新增：为标签样式定义一个接口
interface TagColorStyle {
  font: ResourceColor;
  bg: ResourceColor;
}
// 新增：用代码绘制一个加号图标组件
@Component
struct PlusIcon {
  // 使用不会冲突的属性名
  iconSize: number = 24
  iconColor: ResourceColor = Color.White
  iconStrokeWidth: number = 3

  build() {
    // 在组件内部也使用新的属性名
    Path({ width: this.iconSize, height: this.iconSize })
      .commands(`M ${this.iconSize / 2} 0 L ${this.iconSize / 2} ${this.iconSize} M 0 ${this.iconSize / 2} L ${this.iconSize} ${this.iconSize / 2}`)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
  }
}

// Helper function to get tag colors, based on getSeverityTagType and getStatusTagType
// 修改：更新整个 getTagColor 函数以符合 ArkTS 规范
function getTagColor(type: 'severity' | 'status', value: string): TagColorStyle {
  let style: TagColorStyle;

  if (type === 'severity') {
    switch (value) {
      case '高':
        style = { font: '#aa6203', bg: 'rgba(170, 98, 3, 0.2)' };
        break;
      case '中':
        style = { font: '#906f15', bg: 'rgba(144, 111, 21, 0.2)' };
        break;
      default: // 低
        style = { font: '#059f73', bg: 'rgba(5, 159, 115, 0.2)' };
        break;
    }
  } else { // status
    switch (value) {
      case '已整改':
        style = { font: '#948c8c', bg: 'rgba(148, 140, 140, 0.2)' };
        break;
      case '处理中':
        style = { font: '#00d4ff', bg: 'rgba(0, 212, 255, 0.2)' };
        break;
      case '已确认':
        style = { font: '#906f15', bg: 'rgba(144, 111, 21, 0.2)' };
        break;
      default: // 待确认
        style = { font: '#059f73', bg: 'rgba(5, 159, 115, 0.2)' };
        break;
    }
  }
  return style;
}

@Entry
@Component
struct DefectListPage {
  @State defects: Defect[] = [];
  @State isLoading: boolean = true;
  @State total: number = 0;
  @State currentPage: number = 1;
  private pageSize: number = 10;

  // Corresponds to searchForm in DefectManagement.vue
  @State taskName: string = '';
  @State defectType: string = '';
  @State severity: string = '';
  @State currentStatus: string = '';

  async aboutToAppear() {
    await this.fetchData();
  }

  async fetchData() {
    this.isLoading = true;
    try {
      const result = await DefectService.getDefects({
        currentPage: this.currentPage,
        pageSize: this.pageSize,
        taskName: this.taskName,
        defectType: this.defectType,
        severity: this.severity,
        currentStatus: this.currentStatus
      });
      this.defects = result.list;
      this.total = result.total;
    } catch (e) {
      console.error(JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  // Corresponds to handleSearch and handleReset
  async handleSearch() {
    this.currentPage = 1;
    await this.fetchData();
  }

  async handleReset() {
    this.taskName = '';
    this.defectType = '';
    this.severity = '';
    this.currentStatus = '';
    await this.handleSearch();
  }

  build() {
    Stack() {
    Column() {
      // --- Header ---
      Row() {
        Text('缺陷管理')
          .fontSize(24).fontWeight(FontWeight.Bold)

        // 使用 Blank 组件将按钮推到最右侧
        Blank()

        Button('任务列表')
          .onClick(() => {
            router.pushUrl({ url: 'pages/TaskListPage' })
          })
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF') // 使用一个醒目的颜色
      }
      .width('100%').padding(10). alignItems(VerticalAlign.Center)

      // --- Search Form Area ---
      Column() {
        Row({ space: 10 }) {
          TextInput({ placeholder: '任务名称' }).onChange(val => this.taskName = val).layoutWeight(1)
          TextInput({ placeholder: '缺陷类型' }).onChange(val => this.defectType = val).layoutWeight(1)
        }
        .padding({ top: 5, bottom: 5 })

        Row({ space: 10 }) {
          Select([
            { value: '高' }, { value: '中' }, { value: '低' }
          ])
            .selected(this.severity === '' ? -1 : ['高', '中', '低'].indexOf(this.severity))
            .value('严重程度')
            .onSelect(idx => this.severity = ['高', '中', '低'][idx])
            .layoutWeight(1)

          Select([
            { value: '待确认' }, { value: '已确认' }, { value: '处理中' }, { value: '已整改' }
          ])
            .selected(this.currentStatus === '' ? -1 : ['待确认', '已确认', '处理中', '已整改'].indexOf(this.currentStatus))
            .value('当前状态')
            .onSelect(idx => this.currentStatus = ['待确认', '已确认', '处理中', '已整改'][idx])
            .layoutWeight(1)
        }
        .padding({ top: 5, bottom: 5 })

        Row({ space: 10 }) {
          Button('搜索').onClick(() => this.handleSearch()).layoutWeight(1).type(ButtonType.Capsule)
          Button('重置').onClick(() => this.handleReset()).layoutWeight(1).type(ButtonType.Normal)
        }
      }
      .padding(10)
      .backgroundColor('#f0f2f5')
      .borderRadius(8)

      // --- Defect List ---
      List({ space: 10 }) {
        ListItem() {
          // Table Header
          Row() {
            Text('缺陷编号').layoutWeight(2)
            Text('关联任务').layoutWeight(2)
            Text('严重程度').layoutWeight(1)
            Text('当前状态').layoutWeight(1)
            Text('发现时间').layoutWeight(2)
          }
          .padding(10)
          .backgroundColor('#e4e8f1')
        }

        ForEach(this.defects, (defect: Defect) => {
          ListItem() {
            Row() {
              Text(defect.defectId).layoutWeight(2)
              Text(defect.taskName).layoutWeight(2)
              Text(defect.severity)
                .fontColor(getTagColor('severity', defect.severity).font)
                .backgroundColor(getTagColor('severity', defect.severity).bg)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
                .layoutWeight(1)
              Text(defect.currentStatus)
                .fontColor(getTagColor('status', defect.currentStatus).font)
                .backgroundColor(getTagColor('status', defect.currentStatus).bg)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
                .layoutWeight(1)
              Text(defect.discoveryTime).layoutWeight(2)
            }
            .padding(10)
            .onClick(() => {
              // Navigate to detail page, passing the whole object
              router.pushUrl({
                url: 'pages/DefectDetailPage',
                params: { defect: JSON.stringify(defect) }
              })
            })
          }
        }, (item: Defect) => item.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 1, color: '#e0e0e0' })

      // --- Pagination ---
      Row({ space: 10 }) {
        Text(`总计 ${this.total} 条`)
        Button('上一页').enabled(this.currentPage > 1).onClick(() => {
          this.currentPage--;
          this.fetchData();
        })
        Text(`${this.currentPage} / ${Math.ceil(this.total / this.pageSize)}`)
        Button('下一页').enabled(this.currentPage * this.pageSize < this.total).onClick(() => {
          this.currentPage++;
          this.fetchData();
        })
      }
      .justifyContent(FlexAlign.Center)
      .padding(10)

      // --- Add Button ---
      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        Row({ space: 8 }) {
          // 修改：使用我们自己绘制的图标
          PlusIcon({ iconSize: 20, iconColor: Color.White, iconStrokeWidth: 3 })
          Text('新增缺陷').fontSize(16).fontColor(Color.White)
        }
      }
      .position({ x: '80%', y: '85%' })
      .width(140).height(50)
      .onClick(() => router.pushUrl({ url: 'pages/AddDefectPage' }))
    }
    .width('100%').height('100%').padding(10).backgroundColor('#f9f9f9')

    // 修改 3：使用 if 条件渲染来替代 overlay
    if (this.isLoading) {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        LoadingProgress().width(50)
        Text('加载中...').fontSize(16).margin({ top: 10 })
      }
      .width('100%').height('100%').backgroundColor('rgba(255, 255, 255, 0.8)')
    }
  }
  }
}