(block_body) @indent.begin
"}" @indent.end

(argument_list) @indent.begin
")" @indent.end

(clause
  value: (tuple_expression)) @indent.begin

(transition_block) @indent.begin
(for_block) @indent.begin
(if_block) @indent.begin
