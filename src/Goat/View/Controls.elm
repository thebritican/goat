module Goat.View.Controls exposing (view, viewDropdownMenu)

import Array.Hamt exposing (Array)
import Color exposing (Color)
import Goat.Annotation exposing (Annotation, Drawing(..), LineType(..), ShapeType(..), shapes, spotlights)
import Goat.Annotation.Shared exposing (AnnotationAttributes, StrokeStyle(..))
import Goat.Environment exposing (OperatingSystem(..))
import Goat.Model exposing (AttributeDropdown(..), Model)
import Goat.Update exposing (Msg(..), drawingsAreEqual, isSpotlightDrawing, isCtrlPressed)
import Goat.View.Icons as Icons
import Goat.View.EventUtils exposing (stopPropagationAndDefault)
import Json.Decode as Json
import Html exposing (Attribute, Html, button, div, h2, h3, img, li, p, text, ul)
import Html.Attributes exposing (attribute, class, classList, disabled, id, src, style, title)
import Html.Events exposing (onClick, onMouseDown, onMouseUp, onWithOptions)
import Rocket exposing ((=>))
import UndoList exposing (UndoList)
import Color exposing (Color)
import Goat.Annotation as Annotation
import Goat.Annotation.Shared exposing (StrokeStyle)


strokeColors : List Color
strokeColors =
    [ Color.rgb 255 0 212
    , Color.rgb 255 0 0
    , Color.rgb 73 0 255
    , Color.rgb 0 202 255
    , Color.rgb 16 255 0
    , Color.rgb 255 226 0
    , Color.rgb 255 129 0
    , Color.black
    , Color.white
    ]


fills : List (Maybe Color)
fills =
    [ Nothing
    , Just (Color.rgb 255 0 212)
    , Just (Color.rgb 255 0 0)
    , Just (Color.rgb 73 0 255)
    , Just (Color.rgb 0 202 255)
    , Just (Color.rgb 16 255 0)
    , Just (Color.rgb 255 226 0)
    , Just (Color.rgb 255 129 0)
    , Just Color.black
    , Just Color.white
    ]


strokeStyles : List StrokeStyle
strokeStyles =
    Annotation.strokeStyles


fontSizes : List Int
fontSizes =
    [ 14
    , 16
    , 20
    , 26
    , 32
    , 40
    ]


view : Model -> AnnotationAttributes -> (AttributeDropdown -> Html Msg) -> Html Msg
view model annotationAttrs toDropdownMenu =
    div
        [ class "controls" ]
        [ viewNavigationControls
        , viewHistoryControls model.operatingSystem model.edits
        , viewDrawingButtons model annotationAttrs toDropdownMenu
        ]


viewNavigationControls : Html Msg
viewNavigationControls =
    div [ class "navigation-controls" ]
        [ button [ onClick ReturnToImageSelection, class "cancel-button" ] [ text "Back" ]
        , button [ onClick Save, class "save-button" ] [ text "Save" ]
        ]


viewHistoryControls : OperatingSystem -> UndoList (Array Annotation) -> Html Msg
viewHistoryControls os edits =
    div [ class "history-controls" ]
        [ button
            [ onClick Undo
            , class "history-button"
            , disabled ((not << UndoList.hasPast) edits)
            , title <|
                case os of
                    MacOS ->
                        "Undo (Cmd-Z)"

                    Windows ->
                        "Undo (Ctrl + Z)"
            ]
            [ Icons.viewUndoArrow ]
        , button
            [ onClick Redo
            , class "history-button flip"
            , disabled ((not << UndoList.hasFuture) edits)
            , title <|
                case os of
                    MacOS ->
                        "Redo (Cmd-Shift-Z)"

                    Windows ->
                        "Redo (Ctrl + Shift + Z)"
            ]
            [ Icons.viewUndoArrow ]
        ]


viewDrawingButtons : Model -> AnnotationAttributes -> (AttributeDropdown -> Html Msg) -> Html Msg
viewDrawingButtons { operatingSystem, drawing, shape, spotlight } { strokeColor, fill, strokeStyle, fontSize } toDropdownMenu =
    div [ class "columns" ]
        [ viewDrawingButton operatingSystem drawing (DrawLine Arrow)
        , viewDrawingButton operatingSystem drawing DrawFreeHand
        , viewDrawingButton operatingSystem drawing DrawTextBox
        , viewShapesDropdown toDropdownMenu drawing shape operatingSystem
        , viewSpotlightsDropdown toDropdownMenu drawing spotlight operatingSystem
        , viewDrawingButton operatingSystem drawing DrawPixelate
        , viewStrokeColorDropdown toDropdownMenu strokeColor operatingSystem
        , viewFillDropdown toDropdownMenu fill operatingSystem
        , viewStrokeStyleDropdown toDropdownMenu strokeStyle operatingSystem
        , viewFontSizeDropdown toDropdownMenu operatingSystem
        ]


delayedToggleAttributes : AttributeDropdown -> List (Attribute Msg)
delayedToggleAttributes attributeDropdown =
    [ onMouseDown (WaitForDropdownToggle attributeDropdown)
    , onMouseUp CancelDropdownWait
    ]


viewShapesDropdown : (AttributeDropdown -> Html Msg) -> Drawing -> Drawing -> OperatingSystem -> Html Msg
viewShapesDropdown toDropdownMenu selectedDrawing curShape os =
    div [ class "dropdown-things" ]
        [ button
            ([ onWithOptions "contextmenu" stopPropagationAndDefault (Json.succeed (ToggleDropdown ShapesDropdown))
             , classList
                [ "drawing-button" => True
                , "drawing-button--selected" => List.member selectedDrawing shapes
                ]
             , title (drawingToTitle os curShape)
             ]
                ++ delayedToggleAttributes ShapesDropdown
            )
            [ viewShapeSvg curShape
            , Icons.viewCornerArrow
            ]
        , toDropdownMenu ShapesDropdown
        ]


viewSpotlightsDropdown : (AttributeDropdown -> Html Msg) -> Drawing -> Drawing -> OperatingSystem -> Html Msg
viewSpotlightsDropdown toDropdownMenu selectedDrawing curSpotlight os =
    div [ class "dropdown-things" ]
        [ button
            ([ onWithOptions "contextmenu" stopPropagationAndDefault (Json.succeed (ToggleDropdown SpotlightsDropdown))
             , classList
                [ "drawing-button" => True
                , "drawing-button--selected" => List.member selectedDrawing spotlights
                , "drawing-button--spotlight" => True
                ]
             , title (drawingToTitle os curSpotlight)
             ]
                ++ delayedToggleAttributes SpotlightsDropdown
            )
            [ viewShapeSvg curSpotlight
            , Icons.viewCornerArrow
            ]
        , toDropdownMenu SpotlightsDropdown
        ]


viewFontSizeDropdown : (AttributeDropdown -> Html Msg) -> OperatingSystem -> Html Msg
viewFontSizeDropdown toDropdownMenu os =
    div [ class "dropdown-things" ]
        [ button
            [ onClick <| ToggleDropdown Fonts
            , class "drawing-button"
            , title <|
                case os of
                    MacOS ->
                        "Font Sizes (N)"

                    Windows ->
                        "Fon̲t Sizes"
            ]
            [ Icons.viewFontSize
            ]
        , toDropdownMenu Fonts
        ]


viewFontSizeOptions : Int -> Html Msg
viewFontSizeOptions fontSize =
    fontSizes
        |> List.map (viewFontSizeOption fontSize)
        |> div [ class "dropdown-options" ]


viewFillOptions : Maybe Color -> Html Msg
viewFillOptions fill =
    fills
        |> List.map (viewFillOption fill)
        |> div [ class "dropdown-options" ]


viewStrokeColorOptions : Color -> Html Msg
viewStrokeColorOptions strokeColor =
    strokeColors
        |> List.map (viewStrokeColorOption strokeColor)
        |> div [ class "dropdown-options" ]


viewFillOption : Maybe Color -> Maybe Color -> Html Msg
viewFillOption selectedFill fill =
    button
        [ classList
            [ "dropdown-button" => True
            , "dropdown-button--selected" => selectedFill == fill
            ]
        , onClick (SelectFill fill)
        ]
        [ Icons.viewFill fill ]


viewStrokeColorOption : Color -> Color -> Html Msg
viewStrokeColorOption selectedColor color =
    button
        [ classList
            [ "dropdown-button" => True
            , "dropdown-button--selected" => selectedColor == color
            ]
        , onClick (SelectStrokeColor color)
        ]
        [ Icons.viewStrokeColor color ]


viewFontSizeOption : Int -> Int -> Html Msg
viewFontSizeOption selectedFontSize fontSize =
    button
        [ classList
            [ "dropdown-button" => True
            , "dropdown-button--selected" => selectedFontSize == fontSize
            ]
        , onClick (SelectFontSize fontSize)
        ]
        [ text <| toString <| fontSize ]


viewStrokeStyleDropdown : (AttributeDropdown -> Html Msg) -> StrokeStyle -> OperatingSystem -> Html Msg
viewStrokeStyleDropdown toDropdownMenu strokeStyle os =
    div
        [ class "dropdown-things" ]
        [ button
            [ onClick <| ToggleDropdown Strokes
            , class "drawing-button"
            , title <|
                case os of
                    MacOS ->
                        "Stroke Styles (S)"

                    Windows ->
                        "S̲troke Styles"
            ]
            [ Icons.viewStrokeStyle strokeStyle
            ]
        , toDropdownMenu Strokes
        ]


viewFillDropdown : (AttributeDropdown -> Html Msg) -> Maybe Color -> OperatingSystem -> Html Msg
viewFillDropdown toDropdownMenu fill os =
    div
        [ class "dropdown-things" ]
        [ button
            [ onClick <| ToggleDropdown Fills
            , class "drawing-button"
            , title <|
                case os of
                    MacOS ->
                        "Fills (F)"

                    Windows ->
                        "F̲ills"
            ]
            [ Icons.viewFill fill
            ]
        , toDropdownMenu Fills
        ]


viewStrokeColorDropdown : (AttributeDropdown -> Html Msg) -> Color -> OperatingSystem -> Html Msg
viewStrokeColorDropdown toDropdownMenu strokeColor os =
    div
        [ class "dropdown-things" ]
        [ button
            [ onClick <| ToggleDropdown StrokeColors
            , class "drawing-button"
            , title <|
                case os of
                    MacOS ->
                        "Stroke Colors (K)"

                    Windows ->
                        "Strok̲e Colors"
            ]
            [ Icons.viewStrokeColor strokeColor
            ]
        , toDropdownMenu StrokeColors
        ]


viewStrokeStyleOptions : StrokeStyle -> Html Msg
viewStrokeStyleOptions strokeStyle =
    strokeStyles
        |> List.map (viewStrokeStyleOption strokeStyle)
        |> div [ class "dropdown-options" ]


viewStrokeStyleOption : StrokeStyle -> StrokeStyle -> Html Msg
viewStrokeStyleOption selectedStrokeStyle strokeStyle =
    button
        [ classList
            [ "dropdown-button" => True
            , "dropdown-button--selected" => selectedStrokeStyle == strokeStyle
            ]
        , onClick (SelectStrokeStyle strokeStyle)
        ]
        [ Icons.viewStrokeStyle strokeStyle ]


viewDropdownMenu : Maybe AttributeDropdown -> Drawing -> AnnotationAttributes -> AttributeDropdown -> Html Msg
viewDropdownMenu maybeDropdown drawing annotationAttrs selectedOption =
    Maybe.map (viewDropdownOptions drawing annotationAttrs selectedOption) maybeDropdown
        |> Maybe.withDefault (text "")


viewDropdownOptions : Drawing -> AnnotationAttributes -> AttributeDropdown -> AttributeDropdown -> Html Msg
viewDropdownOptions drawing { fill, strokeColor, strokeStyle, fontSize } selectedOption editOption =
    if selectedOption /= editOption then
        text ""
    else
        case editOption of
            ShapesDropdown ->
                viewShapesOptions drawing

            SpotlightsDropdown ->
                viewSpotlightsOptions drawing

            Fonts ->
                viewFontSizeOptions fontSize

            Fills ->
                viewFillOptions fill

            StrokeColors ->
                viewStrokeColorOptions strokeColor

            Strokes ->
                viewStrokeStyleOptions strokeStyle


viewShapesOptions : Drawing -> Html Msg
viewShapesOptions drawing =
    shapes
        |> List.map (viewDrawingOption drawing)
        |> div [ class "dropdown-options" ]


viewDrawingOption : Drawing -> Drawing -> Html Msg
viewDrawingOption selectedDrawing drawing =
    button
        [ classList
            [ "dropdown-button" => True
            , "dropdown-button--selected" => selectedDrawing == drawing
            , "dropdown-button--spotlight" => List.member drawing spotlights
            ]
        , onClick (ChangeDrawing drawing)
        ]
        [ viewShapeSvg drawing ]


viewSpotlightsOptions : Drawing -> Html Msg
viewSpotlightsOptions drawing =
    spotlights
        |> List.map (viewDrawingOption drawing)
        |> div [ class "dropdown-options" ]


viewDrawingButton : OperatingSystem -> Drawing -> Drawing -> Html Msg
viewDrawingButton os selectedDrawing drawing =
    button
        [ classList
            [ "drawing-button" => True
            , "drawing-button--selected" => drawingsAreEqual selectedDrawing drawing
            , "drawing-button--spotlight" => isSpotlightDrawing drawing
            ]
        , title (drawingToTitle os drawing)
        , onClick <| ChangeDrawing drawing
        ]
        [ viewShapeSvg drawing ]


drawingToTitle : OperatingSystem -> Drawing -> String
drawingToTitle os drawing =
    case os of
        MacOS ->
            macDrawingToTitle drawing

        Windows ->
            windowsDrawingToTitle drawing


windowsDrawingToTitle : Drawing -> String
windowsDrawingToTitle drawing =
    case drawing of
        DrawLine lineType ->
            case lineType of
                Arrow ->
                    "A̲rrow"

                StraightLine ->
                    "L̲ine"

        DrawFreeHand ->
            "Free H̲and"

        DrawShape shapeType ->
            case shapeType of
                Rect ->
                    "R̲ectangle"

                RoundedRect ->
                    "Ro̲unded Rectangle"

                Ellipse ->
                    "E̲llipse"

        DrawTextBox ->
            "T̲ext"

        DrawSpotlight shapeType ->
            case shapeType of
                Rect ->
                    "Spotlig̲ht Rectangle"

                RoundedRect ->
                    "Spotlight Rounded Rec̲tangle"

                Ellipse ->
                    "Spotlight Elli̲pse"

        DrawPixelate ->
            "P̲ixelate"


macDrawingToTitle : Drawing -> String
macDrawingToTitle drawing =
    case drawing of
        DrawLine lineType ->
            case lineType of
                Arrow ->
                    "Arrow (A)"

                StraightLine ->
                    "Line (L)"

        DrawFreeHand ->
            "Free Hand (H)"

        DrawShape shapeType ->
            case shapeType of
                Rect ->
                    "Rectangle (R)"

                RoundedRect ->
                    "Rounded Rectangle (O)"

                Ellipse ->
                    "Ellipse (E)"

        DrawTextBox ->
            "Text (T)"

        DrawSpotlight shapeType ->
            case shapeType of
                Rect ->
                    "Spotlight Rectangle (G)"

                RoundedRect ->
                    "Spotlight Rounded Rectangle (C)"

                Ellipse ->
                    "Spotlight Ellipse (I)"

        DrawPixelate ->
            "Pixelate (P)"


viewShapeSvg : Drawing -> Html Msg
viewShapeSvg drawing =
    case drawing of
        DrawLine lineType ->
            case lineType of
                StraightLine ->
                    Icons.viewLine

                Arrow ->
                    Icons.viewArrow

        DrawFreeHand ->
            Icons.freeHand

        DrawShape shapeType ->
            case shapeType of
                Rect ->
                    Icons.viewRectangle

                RoundedRect ->
                    Icons.viewRoundedRectangle

                Ellipse ->
                    Icons.viewEllipse

        DrawTextBox ->
            Icons.viewText

        DrawSpotlight shapeType ->
            case shapeType of
                Rect ->
                    Icons.viewSpotlightRect

                RoundedRect ->
                    Icons.viewSpotlightRoundedRect

                Ellipse ->
                    Icons.viewSpotlightEllipse

        DrawPixelate ->
            Icons.viewPixelate
