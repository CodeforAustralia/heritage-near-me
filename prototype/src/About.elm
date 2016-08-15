module About (view) where

import Html exposing (Html, section, header, div, p, span, img, a, i, text)
import Html.Attributes exposing (class, src, href)


{-| The main HTML view for about page  -}
view : Html
view =
    let
        appInfo =
            { image = "images/logo.png"
            , description = "Heritage Near Me is a government initiative to implement transformational change to protect, share, and celebrate heritage in NSW at the local level by working closely with local government and communities to ensure that local heritage values have greater recognition."
            , title = "Heritage Near Me"
            , url = "http://github.com/CodeforAustralia/heritage-near-me"
            }
        creditInfo =
            { image = "images/logo-code-for-australia.png"
            , description = "Code for Australia is nonprofit whose vision is a responsive government that works seamlessly with the public to create meaningful change through technology. This project was built by Code for Australia's 2016 fellows in Sydney."
            , title = "Code for Australia"
            , url = "http://codeforaustralia.org"
            }
    in
        div [class "content-area"]
            [ aboutSectionHtml appInfo
            , aboutSectionHtml creditInfo
            ]



type alias URL = String

type alias AboutEntry =
    { image : URL
    , description : String
    , title : String
    , url : URL
    }

aboutSectionHtml : AboutEntry -> Html
aboutSectionHtml entry =
    section []
        [ header []
            [ img [src entry.image, class "about-image"] [] ]
        , div []
            [ p [] [text entry.description] ]
        , div []
            [ linkHtml entry.title entry.url ]
        ]


{-| The HTML for a single story link -}
linkHtml : String -> String -> Html
linkHtml name url = a [class "block-link", href url]
    [ text name
    , span [class "link-arrow"]
        [ span [class "external-link"] [text "External Link"]
        , i [class "fa fa-angle-right"] []
        ]
    ]