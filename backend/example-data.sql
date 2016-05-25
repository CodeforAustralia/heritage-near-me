INSERT INTO story (id, title, blurb, story, dateStart, dateEnd) VALUES (1, 'The Rum Track', 'Places associated with the Rum Rebellion, the only successful armed takeover of government in Australian history', 'On 26th January 1808, officers and men of the New South Wales Corps marched to Government House in Sydney in an act of rebellion against Governor William Bligh. Bligh was arrested and the colony was placed under military rule. This was the only time in Australian history that a government was overthrown by a military coup.

The military stayed in power for two years until Lachlan Macquarie, the fifth Governor of NSW, assumed office at the beginning of 1810. The overthrow of Bligh much later became known as the ‘Rum Rebellion’ because the NSW Corps was heavily involved in the trade in rum in the colony and was nicknamed the ‘Rum Corps’. The term ‘Rum Rebellion’ was not used at the time. The factors leading up to Bligh’s arrest had much less to do with the rum trade and much more to do with a battle for power between the military and civil elites of the colony and the Governor.

A number of sites associated with the rebellion are listed as heritage items, although not always for their associations with the rebellion.', date '1808-01-26', date '1810-01-01');
INSERT INTO story (id, title, blurb, story) VALUES (2, 'Experiment Farm & Cottage', 'The site of the first land grant, where James Ruse proved self-sufficiency was possible.', 'Discover the simple, yet elegant, lives of early colonial setters at Experiment Farm. On the site of the first land grant in the Australia and the first to be granted to a freed convict, James Ruse, this farm was the Governor Phillip’s earliest agricultural ‘experiment’ to determine the period required in which a settler could become self-supporting and its initial success encouraged Phillip to open the Parramatta area to free settlement.

By 1791 Ruse had successfully farmed the 30 acre site as an experiment in self-sufficiency, proving that a new settler could feed and shelter his family with relatively little assistance to get started. The Indian-style bungalow there today was built by Surgeon John Harris, who purchased the land from Ruse in 1793 for £ 40. It is thought to have been built by c1835. It is one of Australia’s oldest standing properties and features in an 1837 sketch and subsequent watercolour by Conrad Martens. The house is furnished to reflect the home of Surgeon Harris, with simple but elegant pieces from National Trust’s collection of early colonial furniture, the largest of its kind in Australia. In the year 2000, the National Trust landscaped and planted the immediate grounds, using evidence from early paintings, plant catalogues and photographs to recreate, as far as possible, an authentic setting for the cottage. Guided tours are available at Experiment Farm Cottage, and a permanent display in the cellar tells the story of the site in all phases of its occupation; Indigenous and colonial to the present day. Experiment Farm Cottage is part of an historical precinct which includes Hambledon Cottage (1824), Elizabeth Farm (1793) and the Queen’s Wharf, all within easy walking distance of each other. Children love exploring the life of Ruse’s family, learning about self sufficiency, Harris’ role as a colonial surgeon and the workings of an early colonial household. The cottage garden is a hands-on sensory garden. A friendly welcome awaits at Experiment Farm Cottage as you explore and embrace its past occupants’ stories.');
INSERT INTO story (id, title, blurb, story) VALUES (3, 'Old Government House', 'On the site of Australia’s first inland settlement stands Australia’s oldest public building', 'Old Government House is a former country residence used by 10 early governors of New South Wales between 1800 and 1847, located in Parramatta Park in Parramatta, New South Wales, now a suburb of Sydney. It is considered a property of national and international significance as an archaeological resource. It also serves to demonstrate how the British Empire expanded and Australian society has evolved since 1788

The Crescent is the site where Governor Phillip established Australia’s first inland settlement, Parramatta, on 2 November 1788. It is located on the Burramattagal’s traditional hunting grounds in present-day Parramatta Park. On the hillside above the crescent-shaped ‘alluvial flats contained in a bend in the river,’ Parramatta’s first building was constructed as part of the fortified camp known as The Redoubt, which was completed in July 1789. The first Government House in Parramatta also stood within The Crescent from 1790 until 1799 when Old Government House was constructed.

On 24 April 1788 a small party of the colonists led by Governor Phillip continued to explore along the Parramatta River until they came upon The Crescent, so named because a bend in the Parramatta River had cut ‘a semi-circular shape into the hill whilst the river formed a [fresh water] billabong below.’ The governor made plans to return in spring to establish the town that became Parramatta.

The first Government House in the colony was built at Sydney Cove in 1788 but the first Government House in Parramatta was built for Governor Phillip in 1790 on the ascending hill of The Crescent. It was a small single-storey cottage measuring 44 feet (approximately 4 m) long and 16 feet (4.9 m) wide made from lath and plaster. Archaeological excavations have revealed remnants of a carriage entrance built by convicts which was also a part of Phillip’s original Government House.

By 1799 Phillip’s Government House had deteriorated so much that a new Government House was constructed higher up on the summit of the same hill at The Crescent. This ‘new’ Government House is now referred to as ‘Old Government House.’ In 1799 the building only consisted of the main central block as the side extensions that are visible today were added by the Macquaries between 1815 and 1817.');

INSERT INTO photo (id, photo) VALUES (1, 'http://acms.sl.nsw.gov.au/_DAMx/image/19/167/a128113h.jpg');
INSERT INTO photo (id, photo) VALUES (2, 'http://dictionaryofsydney.org/files/full/98719481af038d3ed56f5f9160733914606b6a21');
INSERT INTO photo (id, photo) VALUES (3, 'https://www.nationaltrust.org.au/wp-content/uploads/2015/09/Old-Government-House-01-Jonathan-Miller-1920x616.jpg');
INSERT INTO photo (id, photo) VALUES (4, 'http://d2pt3kmt7dz3yl.cloudfront.net/images/269/large_df23f9bc.jpg');
INSERT INTO photo (id, photo) VALUES (5, 'https://upload.wikimedia.org/wikipedia/commons/2/23/William_Bligh_-_Project_Gutenberg_eText_15411.jpg');


INSERT INTO story_photo (story_id, photo_id) VALUES (1, 1);
INSERT INTO story_photo (story_id, photo_id) VALUES (1, 4);
INSERT INTO story_photo (story_id, photo_id) VALUES (1, 5);
INSERT INTO story_photo (story_id, photo_id) VALUES (2, 2);
INSERT INTO story_photo (story_id, photo_id) VALUES (3, 3);

INSERT INTO site (id, name, heritageItemId, suburb, latitude, longitude) VALUES (1, 'Experiment Farm & Cottage', 5051403, 'Harris Park', '-33.8197280468', '151.0126189980');
INSERT INTO site (id, name, heritageItemId, suburb, latitude, longitude) VALUES (2, 'Old Government House', 5051462, 'Parramatta', '-33.8090998594', '150.9967517580');

INSERT INTO story_site (story_id, site_id) VALUES (2, 1);
INSERT INTO story_site (story_id, site_id) VALUES (3, 2);