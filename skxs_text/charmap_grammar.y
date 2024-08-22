charmap_section ::= current_charmap_definition charmaps.
charmap_section ::= charmap_section current_charmap_definition charmaps.
charmaps ::= add_charmap.
charmaps ::= charmaps add_charmap.
current_charmap_definition ::= NEWCHARMAP CHARMAPNUM.
add_charmap ::= CHARMAP CHARACTER COMMA HEXNUM.
