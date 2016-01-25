import Types exposing (..)
import Story
import StartApp.Simple as StartApp

main = StartApp.start { model = exampleStory, view = Story.view, update = Story.update }

exampleStory =
    { title = "Foundations laid for the first Town Hall site in Parramatta."
    , photo = "http://arc.parracity.nsw.gov.au/wp-content/uploads/2014/09/Parramatta-Town-Hall-Map.jpg"
    , story = """Parramatta’s Town Hall site was established when Governor Phillip set aside the land in his plan for Parramatta, thus making it the oldest town hall site in Australia.  Foundations were laid for a Town Hall in 1792, [presumably at the original site next to the Parramatta River and Church Street] but other building projects received priority. Construction for the Parramatta Town Hall was initiated over two stages, from 1879 to 1883.
Governor Macquarie used the site as a Market Place by 1812. The market sold all the produce of the district, and animals for sale were penned up there. The list of public works undertaken during administration of Governor Macquarie includes “A public Market Place, with store for Grain and Pens for Cattle, enclosed with a high Paling in the centre of the Town, consisting of three acres of ground” (1). This site was used consistently as a market place until 1878 when the site began to be prepared for the construction of the Town Hall.
This site was also where the Annual Meeting of the Aboriginal Tribes at Parramatta was held, which Governor Macquarie began in in 1816 and continued to 1833."""
    }
