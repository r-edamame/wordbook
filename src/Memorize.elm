
module Memorize exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser

import Type
import Config exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)

import Http
import HttpBuilder

import Debug


----------------------
-- Type Definitions --
----------------------

type Visible
    = Shown
    | Hidden

type State
    = AnswerHidden
    | AnswerShown
    | WaitingQuestion
    | WaitingResult
    | NoData

type Error
    = HTTPRequestError String
    | ResponseError String

type Msg
    = Error Error
    | RecieveSentence Type.Sentence
    | ShowAnswer
    | PostSucceeded
    | SendCorrectInfo Bool

type alias Model =
    { sentence : Maybe Type.Sentence
    , errorString : Maybe String
    , state : State
    , token : String
    }

-------------------
-- HTTP Requests --
-------------------

errToMsg : (String -> Msg) -> Http.Error -> Msg
errToMsg toMsg error = case error of
    Http.BadUrl _ -> toMsg "bad url"
    Http.Timeout -> toMsg "timeout"
    Http.NetworkError -> toMsg "network error"
    Http.BadStatus status -> toMsg <| "bad status: " ++ String.fromInt status
    Http.BadBody body -> toMsg <| "bad body: " ++ body

type alias ResponseError = String


decodeResponse : Decoder a -> Decoder (Result ResponseError a)
decodeResponse contentDecoder =
    Decode.field "status" Decode.string
        |> Decode.andThen (\status -> case status of
            "ok" -> Decode.map Ok (Decode.field "content" contentDecoder)
            "error" -> Decode.map Err (Decode.field "message" Decode.string)
            _ -> Decode.fail "invalid json response")

getRandomSentence : String -> Cmd Msg
getRandomSentence token =
    let
        handle res = case res of
            Ok ok -> case ok of
                Ok sentence -> RecieveSentence sentence
                Err mes -> Error (ResponseError mes)
            Err err -> errToMsg (HTTPRequestError>>Error) err
        endpoint = apiHost ++ getQuestionPath
    in
        HttpBuilder.get endpoint
            |> HttpBuilder.withExpect (Http.expectJson handle <| decodeResponse Type.decodeSentence)
            |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ token)
            |> HttpBuilder.request


postCorrectInfo : String -> Type.Sentence -> Bool -> Cmd Msg
postCorrectInfo token sentence corrected =
    let
        json = Encode.object
            [ ("questionId", Encode.string sentence.id)
            , ("corrected", Encode.bool corrected)
            ]
        handle res = case res of
            Ok ok -> case ok of
                Ok s -> RecieveSentence s
                Err mes -> Error (ResponseError mes)
            Err err -> errToMsg (HTTPRequestError>>Error) err
        endpoint = apiHost ++ postCorrectInfoPath
    in
        HttpBuilder.post endpoint
            |> HttpBuilder.withJsonBody json
            |> HttpBuilder.withExpect(Http.expectJson handle <| decodeResponse Type.decodeSentence)
            |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ token)
            |> HttpBuilder.request

-------------------------
-- The Elm Archtecture --
-------------------------

init : String -> (Model, Cmd Msg)
init token =
    let
        model =
            { sentence=Nothing
            , errorString=Nothing
            , state=WaitingQuestion
            , token=token
            }
    in
        (model, getRandomSentence token)

errorHandle : Error -> Model -> (Model, Cmd Msg)
errorHandle error model = case error of
    HTTPRequestError mes -> (always model <| Debug.log mes (), Cmd.none)
    ResponseError mes -> ({model| errorString=Just mes}, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    Error error -> errorHandle error model
    RecieveSentence sentence -> ({model| sentence=Just sentence, state=AnswerHidden}, Cmd.none)
    PostSucceeded -> ({model| state=WaitingQuestion}, getRandomSentence model.token)
    ShowAnswer -> ({model| state=AnswerShown}, Cmd.none)
    SendCorrectInfo corrected -> case model.sentence of
        Nothing -> (model, Cmd.none)
        Just sentence -> ({model| state=WaitingResult}, postCorrectInfo model.token sentence corrected)
    
subscriptions : Model -> Sub Msg
subscriptions = always Sub.none

--------------------
-- View Functions --
--------------------

view : Model -> Html Msg
view model =
    div []
        [ viewError model.errorString
        , case (model.sentence, model.state) of
            (Nothing, WaitingQuestion) -> case model.errorString of
                Nothing -> text "ロード中"
                _ -> text ""
            (Just sentence, AnswerHidden) -> viewQuestion sentence Hidden viewShowButton
            (Just sentence, AnswerShown) -> viewQuestion sentence Shown <| viewConfirmButton False
            (Just sentence, WaitingQuestion) -> viewQuestion sentence Shown <| viewConfirmButton True
            (Just sentence, WaitingResult) -> viewQuestion sentence Shown <| viewConfirmButton True
            _ -> text "invalid status"
        , viewCreateButton
        ]

originalText original =
    node "with-highlight" [ attribute "color" "#58e", attribute "text" original ] []

hideAnswer text =
    node "hide-answer" [ attribute "text" text ] []

showAnswer text =
    node "with-highlight" [ attribute "color" "#e66", attribute "text" text ] []

viewError error = case error of
    Just mes -> div [] [ text mes ]
    Nothing -> text ""

viewShowButton =
    div [ class "show-answer button-wrapper" ]
        [ button [ onClick ShowAnswer ] [ text "開く" ]
        ]
    

viewConfirmButton dis =
    div [ class "confirm button-wrapper" ]
        [ div [ class "button-wrapper" ]
            [ button [ class "correct", onClick <| SendCorrectInfo True, disabled dis ] [ text "覚えてた" ]
            , button [ class "incorrect", onClick <| SendCorrectInfo False, disabled dis ] [ text "覚えてなかった" ]
            ]
        ]

viewCreateButton : Html Msg
viewCreateButton =
    div [ class "create-button" ]
        [ div [ class "button-wrapper" ]
            [ a [ href "#create" ] [ text "+" ]
            ]
        ]

viewQuestion : Type.Sentence -> Visible -> Html Msg -> Html Msg
viewQuestion sentence isShown buttonView =
    div [ class "question container" ]
        [ div [ class "sentence" ]
            [ div [ class "original" ]
                [ div [ class "content" ]
                    [ originalText sentence.japanese
                    ]
                ]
            , div [ class "holed" ]
                [ div [ class "content" ]
                    [ case isShown of
                        Shown -> showAnswer sentence.english
                        Hidden ->hideAnswer sentence.english
                    ]
                ]
            ]
        , buttonView
        ]
