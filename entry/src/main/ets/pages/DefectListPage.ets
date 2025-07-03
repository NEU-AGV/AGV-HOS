// /entry/src/main/ets/pages/DefectListPage.ets

import router from '@ohos.router';
import { Defect } from '../model/Defect';
import ApiService from '../services/ApiService';

// 新增：为 Select 组件的选项定义一个标准接口
interface SelectOption {
  value: string;
}

interface TagColorStyle {
  font: ResourceColor;
  bg: ResourceColor;
}

function getTagColor(type: 'severity' | 'status', value: string): TagColorStyle {
  let style: TagColorStyle;
  if (type === 'severity') {
    switch (value) {
      case '高':
        style = { font: '#aa6203', bg: 'rgba(170, 98, 3, 0.2)' }; break;
      case '中':
        style = { font: '#906f15', bg: 'rgba(144, 111, 21, 0.2)' }; break;
      default:
        style = { font: '#059f73', bg: 'rgba(5, 159, 115, 0.2)' }; break;
    }
  } else {
    switch (value) {
      case '已整改':
        style = { font: '#948c8c', bg: 'rgba(148, 140, 140, 0.2)' }; break;
      case '处理中':
        style = { font: '#00d4ff', bg: 'rgba(0, 212, 255, 0.2)' }; break;
      case '已确认':
        style = { font: '#906f15', bg: 'rgba(144, 111, 21, 0.2)' }; break;
      default:
        style = { font: '#059f73', bg: 'rgba(5, 159, 115, 0.2)' }; break;
    }
  }
  return style;
}

@Component
struct PlusIcon {
  iconSize: number = 24
  iconColor: ResourceColor = Color.White
  iconStrokeWidth: number = 3

  build() {
    Path({ width: this.iconSize, height: this.iconSize })
      .commands(`M ${this.iconSize / 2} 0 L ${this.iconSize / 2} ${this.iconSize} M 0 ${this.iconSize / 2} L ${this.iconSize} ${this.iconSize / 2}`)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
  }
}

@Entry
@Component
struct DefectListPage {
  @State defects: Defect[] = [];
  @State isLoading: boolean = true;
  @State total: number = 0;
  @State currentPage: number = 1;
  private pageSize: number = 10;
  @State taskName: string = '';
  @State defectType: string = '';
  @State severity: string = '';
  @State currentStatus: string = '';

  // 定义 Select 的选项，方便复用
  private severityOptions = ['全部', '高', '中', '低'];
  private statusOptions = ['全部', '待确认', '已确认', '处理中', '已整改'];

  // 修正1：新增 onPageShow，在每次页面显示时刷新数据
  onPageShow(){
    this.fetchData();
  }

  async aboutToAppear() {
    await this.fetchData();
  }

  async fetchData() {
    this.isLoading = true;
    try {
      const result = await ApiService.getDefects({
        currentPage: this.currentPage, pageSize: this.pageSize,
        taskName: this.taskName, defectType: this.defectType,
        severity: this.severity, currentStatus: this.currentStatus
      });
      this.defects = result.list;
      this.total = result.total;
    } catch (e) {
      console.error(JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  async handleSearch() {
    this.currentPage = 1;
    await this.fetchData();
  }

  // 修正2：重置方法现在能正确清空所有UI
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
        Row() {
          Text('缺陷管理')
            .fontSize(24).fontWeight(FontWeight.Bold)
          Blank()
          Button('任务列表')
            .onClick(() => {
              router.pushUrl({ url: 'pages/TaskListPage' })
            })
            .type(ButtonType.Capsule)
            .backgroundColor('#007DFF')
        }
        .width('100%').padding(10)
        .alignItems( VerticalAlign.Center)

        // --- Search Form Area ---
        Column() {
          Row({ space: 10 }) {
            // 修正2：为 TextInput 添加 text 属性实现双向绑定
            TextInput({ placeholder: '任务名称', text: this.taskName })
              .onChange(val => this.taskName = val).layoutWeight(1)
            TextInput({ placeholder: '缺陷类型', text: this.defectType })
              .onChange(val => this.defectType = val).layoutWeight(1)
          }.padding({ top: 5, bottom: 5 })

          Row({ space: 10 }) {
            // 修正3：为 Select 添加 value 属性，使其能显示当前选中项
            Select(this.severityOptions.map((item: string): SelectOption => ({ value: item })))
              .value(this.severity === '' ? '严重程度' : this.severity)
              .selected(this.severityOptions.indexOf(this.severity))
              .onSelect(idx => this.severity = idx === 0 ? '' : this.severityOptions[idx])
              .layoutWeight(1)

            // 修正2：确保“当前状态”的 Select 组件使用自己的 statusOptions 和 currentStatus
            Select(this.statusOptions.map((item: string): SelectOption => ({ value: item })))
              .value(this.currentStatus === '' ? '当前状态' : this.currentStatus)
              .selected(this.statusOptions.indexOf(this.currentStatus === '' ? '全部' : this.currentStatus))
              .onSelect(idx => this.currentStatus = idx === 0 ? '' : this.statusOptions[idx])
              .layoutWeight(1)
          }.padding({ top: 5, bottom: 5 })

          Row({ space: 10 }) {
            Button('搜索').onClick(() => this.handleSearch()).layoutWeight(1).type(ButtonType.Capsule)
            Button('重置').onClick(() => this.handleReset()).layoutWeight(1).type(ButtonType.Normal)
          }
        }
        .padding(10).backgroundColor('#f0f2f5').borderRadius(8)

        // --- Defect List ---
        List({ space: 10 }) {
          ListItem() {
            // 修正1：增加“缺陷类型”列表头
            Row() {
              Text('缺陷编号').layoutWeight(1.5).fontWeight(FontWeight.Bold)
              Text('关联任务').layoutWeight(1.5).fontWeight(FontWeight.Bold)
              Text('缺陷类型').layoutWeight(1).fontWeight(FontWeight.Bold) // 新增
              Text('严重程度').layoutWeight(1).fontWeight(FontWeight.Bold)
              Text('当前状态').layoutWeight(1).fontWeight(FontWeight.Bold)
            }.padding(10).backgroundColor('#e4e8f1')
          }

          ForEach(this.defects, (defect: Defect) => {
            ListItem() {
              Row() {
                Text(defect.defectId).layoutWeight(1.5)
                Text(defect.taskName).layoutWeight(1.5)
                // 修正1：显示缺陷类型
                Text(defect.defectType).layoutWeight(1) // 新增
                Text(defect.severity)
                  .fontColor(getTagColor('severity', defect.severity).font)
                  .backgroundColor(getTagColor('severity', defect.severity).bg)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4)
                  .textAlign(TextAlign.Center).layoutWeight(1)
                Text(defect.currentStatus)
                  .fontColor(getTagColor('status', defect.currentStatus).font)
                  .backgroundColor(getTagColor('status', defect.currentStatus).bg)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4)
                  .textAlign(TextAlign.Center).layoutWeight(1)
              }
              .padding(10)
              .alignItems( VerticalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/DefectDetailPage', params: { defect: JSON.stringify(defect) } })
              })
            }
          }, (item: Defect) => item.id.toString())
        }
        .layoutWeight(1).width('100%').divider({ strokeWidth: 1, color: '#e0e0e0' })

        // --- Pagination ---
        Row({ space: 10 }) {
          Text(`总计 ${this.total} 条`)
          Button('上一页').enabled(this.currentPage > 1).onClick(() => {
            this.currentPage--; this.fetchData();
          })
          Text(`${this.currentPage} / ${this.total === 0 ? 1 : Math.ceil(this.total / this.pageSize)}`)
          Button('下一页').enabled(this.currentPage * this.pageSize < this.total).onClick(() => {
            this.currentPage++; this.fetchData();
          })
        }.justifyContent(FlexAlign.Center).padding(10)

        // --- Add Button ---
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Row({ space: 8 }) {
            PlusIcon({ iconSize: 20, iconColor: Color.White, iconStrokeWidth: 3 })
            Text('新增缺陷').fontSize(16).fontColor(Color.White)
          }
        }
        .position({ x: '80%', y: '85%' })
        .width(140).height(50)
        .onClick(() => router.pushUrl({ url: 'pages/AddDefectPage' }))
      }
      .width('100%').height('100%').padding(10).backgroundColor('#f9f9f9')

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