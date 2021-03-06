module Goat.View.DrawingArea.Vertices exposing (viewVertices, ResizeDirection)

import Color exposing (Color)
import Color.Convert
import Goat.Annotation exposing (SelectState(..), StartPosition, EndPosition)
import Goat.Annotation.Shared exposing (Vertex(..), Vertices(..))
import Svg exposing (Svg, circle, defs, foreignObject, marker, rect, svg)
import Svg.Attributes as Attr


type ResizeDirection
    = NWSE
    | NESW
    | Move


viewVertex : List (Svg.Attribute msg) -> ResizeDirection -> Int -> Int -> Svg msg
viewVertex vertexEvents direction x y =
    circle
        ([ Attr.cx <| toString x
         , Attr.cy <| toString y
         , Attr.r "5"
         , Attr.fill <| Color.Convert.colorToHex Color.blue
         , Attr.stroke "white"
         , Attr.strokeWidth "2"
         , Attr.filter "url(#dropShadow)"
         , Attr.class (directionToCursor direction)
         ]
            ++ vertexEvents
        )
        []


shapeVertices : (Vertex -> List (Svg.Attribute msg)) -> StartPosition -> EndPosition -> Svg msg
shapeVertices toVertexEvents start end =
    let
        ( resizeDir1, resizeDir2, resizeDir3, resizeDir4 ) =
            if start.x < end.x && start.y > end.y then
                ( NESW, NWSE, NWSE, NESW )
            else if start.x < end.x && start.y < end.y then
                ( NWSE, NESW, NESW, NWSE )
            else if start.x > end.x && start.y > end.y then
                ( NWSE, NESW, NESW, NWSE )
            else
                ( NESW, NWSE, NWSE, NESW )
    in
        Svg.g []
            [ viewVertex (toVertexEvents Start) resizeDir1 start.x start.y
            , viewVertex (toVertexEvents StartPlusX) resizeDir2 end.x start.y
            , viewVertex (toVertexEvents StartPlusY) resizeDir3 start.x end.y
            , viewVertex (toVertexEvents End) resizeDir4 end.x end.y
            ]


lineVertices : (Vertex -> List (Svg.Attribute msg)) -> StartPosition -> EndPosition -> Svg msg
lineVertices toVertexEvents start end =
    Svg.g []
        [ viewVertex (toVertexEvents Start) Move start.x start.y
        , viewVertex (toVertexEvents End) Move end.x end.y
        ]


viewVertices : Vertices -> StartPosition -> EndPosition -> (Vertex -> List (Svg.Attribute msg)) -> SelectState -> Maybe (Svg msg)
viewVertices vertices start end toVertexEvents selectState =
    let
        toVertices =
            case vertices of
                Rectangular ->
                    shapeVertices

                Linear ->
                    lineVertices
    in
        if selectState == SelectedWithVertices then
            Just (toVertices toVertexEvents start end)
        else
            Nothing


directionToCursor : ResizeDirection -> String
directionToCursor direction =
    case direction of
        NWSE ->
            "northWestCursor"

        NESW ->
            "northEastCursor"

        Move ->
            "moveCursor"
