" Syntax highlighting for octocode results

if exists("b:current_syntax")
  finish
endif

" Headers
syntax match OctocodeHeader "^=== .* ===$"
syntax match OctocodeSection "^📄 .*:$"
syntax match OctocodeSection "^📚 .*:$"
syntax match OctocodeSection "^📝 .*:$"

" File paths and line numbers
syntax match OctocodeFile "\v\s+\d+\.\s+[^:]+:\d+-\d+"
syntax match OctocodeDistance "\v\(\d+\.\d+\)$"

" Symbols and metadata
syntax match OctocodeSymbol "\v^\s+Symbols:.*$"
syntax match OctocodeTitle "\v^\s+Title:.*$"

" Instructions
syntax match OctocodeInstruction "^Press .* to .*$"

" Code preview (indented lines)
syntax match OctocodePreview "^\s\{5,\}.*$"

" Highlighting
highlight default link OctocodeHeader Title
highlight default link OctocodeSection Special
highlight default link OctocodeFile Identifier
highlight default link OctocodeDistance Number
highlight default link OctocodeSymbol Function
highlight default link OctocodeTitle String
highlight default link OctocodeInstruction Comment
highlight default link OctocodePreview Comment

let b:current_syntax = "octocode-results"