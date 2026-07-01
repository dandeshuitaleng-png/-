import { HomeUiTokens } from '../components/HomeUiTokens';
import { AppViewModel } from '../viewmodel/AppViewModel';

@ComponentV2
export struct FlipPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('正在翻牌...')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach(this.vm.flippingCategoryNames, (name: string, index: number) => {
          Column() {
            Text(name)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(index === 1 ? HomeUiTokens.FONT_SUBTITLE : HomeUiTokens.FONT_BODY_SMALL)
              .fontWeight(index === 1 ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(index === 1 ? Color.White : $r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(index === 1 ? 2 : 1)
          .height(index === 1 ? HomeUiTokens.FLIP_ACTIVE_CARD_HEIGHT : HomeUiTokens.FLIP_SIDE_CARD_HEIGHT)
          .padding(HomeUiTokens.ITEM_GAP_COMPACT)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(index === 1 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
          .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
          .animation({ duration: HomeUiTokens.FLIP_CARD_TRANSITION_DURATION, curve: Curve.EaseInOut })
        }, (name: string, index: number) => `${index}-${name}`)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('马上揭晓今天的口味')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
    .alignItems(HorizontalAlign.Center)
  }
}
