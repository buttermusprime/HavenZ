class_name Deck
extends RefCounted

## Real Deck/Hand/Discard-pile data structure, generalizing the Phase 1 gray-box's flat
## random-draw-with-replacement card pool into GDD §7's actual Player Turn rules. Deliberately
## generic over CardResource -- no HavenZ-specific card-category logic lives here -- since
## Deck/Hand/Discard is flagged as a Tier-3 extraction candidate (see the roadmap's Modular
## Systems section): basically any deckbuilder needs this exact shape, tile-tactics or not.
##
## Pure runtime state, not authored data -- every field here changes during play, nothing is
## designer-set upfront the way CardResource/TileResource's exported fields are -- so this is
## RefCounted, not Resource.

var draw_pile: Array[CardResource] = []
var hand: Array[CardResource] = []
var discard_pile: Array[CardResource] = []
var hand_size: int

## Per GDD §7: "Player deck shuffles if there are not enough cards to deal the hand and then
## deals [hand_size] cards." Duplicates `cards` rather than taking the caller's original array,
## so later mutation here never surprises whatever built that array.
func _init(cards: Array[CardResource], initial_hand_size: int) -> void:
	hand_size = initial_hand_size
	draw_pile = cards.duplicate()
	draw_pile.shuffle()
	_deal_hand()

func _deal_hand() -> void:
	while hand.size() < hand_size:
		var card := draw_card()
		if card == null:
			break  # deck fully exhausted (draw pile and discard pile both empty) -- deal what we can
		hand.append(card)

## Pops one card from the draw pile, reshuffling the discard pile into it first if the draw pile
## is empty (GDD §7: "If at any point a new card should be drawn AND there are insufficient
## cards, the discard pile is shuffled"). Returns null only on TOTAL exhaustion -- both piles
## empty, e.g. every remaining card is already in hand or has left the cycle via a drop.
func draw_card() -> CardResource:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return null
		draw_pile = discard_pile.duplicate()
		draw_pile.shuffle()
		discard_pile.clear()
	return draw_pile.pop_back()

## Plays the card at `index`: removes it from hand, sends it to the discard pile, and draws a
## replacement (GDD: "When a card is played a new card is drawn... [it goes] into the discard
## pile"). Returns the played card so the caller (session 4.4's resolution branch) can apply its
## effect -- this class only manages the piles, it never resolves a card's effect itself.
func play_card(index: int) -> CardResource:
	var card: CardResource = hand[index]
	hand.remove_at(index)
	discard_pile.append(card)
	var replacement := draw_card()
	if replacement != null:
		hand.append(replacement)
	return card

## Drops the card at `index`: removes it from hand WITHOUT discarding it and WITHOUT drawing a
## replacement. GDD is explicit this is a real penalty ("a new card IS NOT drawn... their hand
## size is reduced the remainder of the turn"), not a discard-pile-bound variant of playing --
## the roadmap's own session-prompt summary ("playing or dropping draws a replacement") reads
## like it disagrees, but the GDD's own worked-out Minute-to-Minute Chain rule is unambiguous and
## more authoritative than that summary, so this follows the GDD. The dropped card leaves the
## deck's cycle entirely until re-salvaged later (session 5.3) -- turning it into a real world
## Pickable is session 4.4's job, not this class's; this method only removes it from hand and
## hands the card back to the caller.
func drop_card(index: int) -> CardResource:
	var card: CardResource = hand[index]
	hand.remove_at(index)
	return card
