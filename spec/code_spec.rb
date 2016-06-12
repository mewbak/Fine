require_relative "../lib/parser/parser.rb"
require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/ir/ir.rb"
require_relative "../lib/code/code_generation.rb"

describe "ir" do
    it "generates llvm" do
        data = {
"int foo;" => "@foo = global i32 zeroinitializer\n",
"char foo;" => "@foo = global i8 zeroinitializer\n",
"int foo[42];" => "@foo = global [42 x i32] zeroinitializer\n",
"char foo[42];" => "@foo = global [42 x i8] zeroinitializer\n",
#-------------------------------------------------------------------
"int main(void) { return 0; }" =>
"
define i32 @main() {
    ret i32 0
}",
#-------------------------------------------------------------------
"int main(int foo) { return foo; }" =>
"
define i32 @main(i32 %foo) {
    ret i32 %foo
}",
#-------------------------------------------------------------------
"int foo; int main(void) { return foo; }" =>
"@foo = global i32 zeroinitializer

define i32 @main() {
    ret i32 @foo
}",
# #-------------------------------------------------------------------
# "int foo; int main(void) { foo = 42; return foo; }" =>
# "@foo = global i32 zeroinitializer

# define i32 @main() {
#     store i32 42, i32 @foo
#     ret i32 @foo
# }"
        }
        data.each do |uc, llvm|
            expect(uc_to_llvm(uc)).to eq llvm
        end
    end

    def uc_to_llvm string
        begin
            ast = Parser.new.parse string
            if semantic_analysis(ast)
                ir = generate_ir ast
                return generate_llvm ir
            end
        rescue Lexer::LexicalError => e
            puts e
        rescue Parser::SyntaxError => e
            puts e
        rescue SemanticError => e
            puts e
        end
    end
end
