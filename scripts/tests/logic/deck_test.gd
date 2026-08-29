# Exercises: res://scripts/deck/deck.gd
extends SceneTree

## First real test file in the project -- session 0.5 set up the folder/header convention
## (res://scripts/tests/{logic,ui,integration}/, the "# Exercises:" header) but nothing populated
## it yet, since no gameplay code existed. This establishes the concrete "how do you actually run
## one of these" pattern future test files should follow: a plain SceneTree script, run directly
## via `godot --headless --script res://scripts/tests/logic/deck_test.gd`, printing PASS/FAIL per
## check and exiting non-zero on any failure. No external test-runner/framework exists yet, and
## building one wasn't asked for by this session -- if the suite grows large enough to need
## discovery/aggregation across many files, that's a real future extraction candidate, not this.
##
## Per this session's own explicit ask: tests against an arbitrary 8-card deck, not just the 5
## gray-box cards, so this proves the real Deck class works in general, not merely replicates
## whatever the gray-box's own fixed pool happened to already do correctly.

var failures := 0

func _check(name: String, ok: bool) -> void:
	if ok:
		print("PASS: ", name)
	else:
		print("FAIL: ", name)
		failures += 1

func _make_cards(count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.id = "test_card_%d" % i
		cards.append(card)
	return cards

func _initialize() -> void:
	var deck := Deck.new(_make_cards(8), 5)

	_check("initial deal fills the hand up to hand_size", deck.hand.size() == 5)
	_check("draw pile holds the rest (8 - 5 = 3)", deck.draw_pile.size() == 3)
	_check("discard pile starts empty", deck.discard_pile.is_empty())

	var played: CardResource = deck.play_card(0)
	_check("play_card returns the played card", played != null)
	_check("hand stays at hand_size after playing (replenished)", deck.hand.size() == 5)
	_check(
		"the played card lands in the discard pile, nowhere else",
		deck.discard_pile.size() == 1 and deck.discard_pile[0] == played and not deck.hand.has(played),
	)
	_check("draw pile shrank by exactly one (the replacement draw)", deck.draw_pile.size() == 2)

	var dropped: CardResource = deck.drop_card(0)
	_check("drop_card returns the dropped card", dropped != null)
	_check(
		"hand shrinks after dropping and is NOT replenished (GDD's explicit drop penalty)",
		deck.hand.size() == 4,
	)
	_check("a dropped card never enters the discard pile", not deck.discard_pile.has(dropped))
	_check("a drop never touches the draw pile", deck.draw_pile.size() == 2)

	# Exhaust the draw pile entirely by playing repeatedly, forcing the next draw to reshuffle
	# from the discard pile instead (GDD §7's explicit reshuffle-on-insufficient-cards rule).
	while deck.draw_pile.size() > 0:
		deck.play_card(0)
	_check("draw pile is empty after exhausting it", deck.draw_pile.is_empty())
	_check("discard pile has accumulated the played cards", deck.discard_pile.size() > 0)

	var reshuffled: CardResource = deck.draw_card()
	_check(
		"drawing against an empty draw pile reshuffles the discard pile instead of failing",
		reshuffled != null,
	)
	_check("the discard pile is empty again immediately after the reshuffle", deck.discard_pile.is_empty())

	# Total exhaustion: a tiny 2-card deck with everything already in hand, nothing left in
	# either pile -- draw_card() must degrade to null, not crash.
	var tiny_deck := Deck.new(_make_cards(2), 2)
	_check("a fully-dealt tiny deck leaves both piles empty", tiny_deck.draw_pile.is_empty() and tiny_deck.discard_pile.is_empty())
	var exhausted: CardResource = tiny_deck.draw_card()
	_check("drawing with both piles genuinely empty returns null rather than erroring", exhausted == null)

	print("")
	if failures == 0:
		print("ALL CHECKS PASSED")
	else:
		print(failures, " CHECK(S) FAILED")
	quit(1 if failures > 0 else 0)
