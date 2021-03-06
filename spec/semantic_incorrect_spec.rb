require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "semantic analysis" do
    def check_semantics relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/incorrect/#{relative_path}"
        content = read_file absolute_path
        semantic_analysis( Parser.new.parse content, show_tokens)
    end
    def semantic_error_message file
        begin
            check_semantics file
        rescue SemanticError => e
            return e.message
        rescue Parser::SyntaxError => e
            return e.message
        end
    end
    it "semantic/se01.c" do
        expect(semantic_error_message("semantic/se01.c")).to eq "Semantic error: 'b' was not defined"
    end
    it "semantic/se02.c" do
        expect(semantic_error_message("semantic/se02.c")).to eq "Semantic error: 'foo' was not defined"
    end
    it "semantic/se03.c" do
        expect(semantic_error_message("semantic/se03.c")).to eq "Semantic error: 'output' was not defined"
    end
    it "semantic/se04.c" do
        expect(semantic_error_message("semantic/se04.c")).to eq "Semantic error: 'a' already defined as variable"
    end
    it "semantic/se05.c" do
        expect(semantic_error_message("semantic/se05.c")).to eq "Semantic error: 'a' already defined as variable"
    end
    it "semantic/se06.c" do
        expect(semantic_error_message("semantic/se06.c")).to eq "Semantic error: function 'a' already implemented"
    end
    it "semantic/se07.c" do
        expect(semantic_error_message("semantic/se07.c")).to eq "Semantic error: attempt to return value from procedure"
    end
    it "semantic/se08.c" do
        expect(semantic_error_message("semantic/se08.c")).to eq "Semantic error: void return from function"
    end
    it "semantic/se09.c" do
        expect(semantic_error_message("semantic/se09.c")).to eq "Semantic error: expression does not match return type"
    end
    it "semantic/se10.c" do
        expect(semantic_error_message("semantic/se10.c")).to eq "Semantic error: 'n' is not an array"
    end
    it "semantic/se11.c" do
        expect(semantic_error_message("semantic/se11.c")).to eq "Semantic error: can not assign to function reference 'a'"
    end
    it "semantic/se12.c" do
        expect(semantic_error_message("semantic/se12.c")).to eq "Semantic error: 'a' is not a function or procedure"
    end
    it "semantic/se13.c" do
        expect(semantic_error_message("semantic/se13.c")).to eq "Semantic error: function foo does not return a value"
    end
    it "semantic/se14.c" do
        expect(semantic_error_message("semantic/se14.c")).to eq  "Semantic error: 'f' is not a function or procedure"
    end
    it "semantic/se15.c" do
        expect(semantic_error_message("semantic/se15.c")).to eq "Semantic error: 'q' expected 3 arguments, but got 2"
    end
    it "semantic/se15_wrong_argument_types.c" do
        expect(semantic_error_message("semantic/se15_wrong_argument_types.c")).to eq "Semantic error: 'q' expected argument at position 2 to be of type int, but got type char"
    end
    it "semantic/se16.c" do
        expect(semantic_error_message("semantic/se16.c")).to eq "Semantic error: 'd' expected 2 arguments, but got 3"
    end
    it "semantic/se17.c" do
        expect(semantic_error_message("semantic/se17.c")).to eq "Semantic error: char-array + int is not defined"
    end
    it "semantic/se18.c" do
            expect(semantic_error_message("semantic/se18.c")).to eq "Semantic error: can not assign to array reference 'a'"
    end
    it "semantic/se19.c" do
        expect(semantic_error_message("semantic/se19.c")).to eq "Semantic error: char-array == int is not defined"
    end
    it "semantic/se20.c" do
        expect(semantic_error_message("semantic/se20.c")).to eq "Semantic error: can not assign to array reference 'a'"
    end
    it "semantic/se21.c" do
        expect(semantic_error_message("semantic/se21.c")).to eq "Semantic error: expression does not match return type"
    end
    it "semantic/se22.c" do
        expect(semantic_error_message("semantic/se22.c")).to eq "Semantic error: char-array + int is not defined"
    end
    it "semantic/se23.c" do
        expect(semantic_error_message("semantic/se23.c")).to eq "Semantic error: 'b' is not an array"
    end
    it "semantic/se24.c" do
        expect(semantic_error_message("semantic/se24.c")).to eq "Semantic error: can not assign to array reference 'b'"
    end
    it "semantic/se25.c" do
        expect(semantic_error_message("semantic/se25.c")).to eq "Semantic error: can not assign to expression"
    end
    it "semantic/se26.c" do
        expect(semantic_error_message("semantic/se26.c")).to eq "Semantic error: 'f' expected argument at position 1 to be of type int-array, but got type char-array"
    end
    it "semantic/se27.c" do
        expect(semantic_error_message("semantic/se27.c")).to eq "Semantic error: attempt to return value from procedure"
    end
    it "semantic/se28.c" do
        expect(semantic_error_message("semantic/se28.c")).to eq "Semantic error: attempt to return value from procedure"
    end
    it "semantic/se29.c" do
        expect(semantic_error_message("semantic/se29.c")).to eq "Semantic error: missing return in 'main'"
    end
    it "semantic/se30.c" do
        expect(semantic_error_message("semantic/se30.c")).to eq "Semantic error: can not assign int-array to variable of type int"
    end
    it "semantic/se31.c" do
        expect(semantic_error_message("semantic/se31.c")).to eq "Semantic error: 'a' already defined as variable"
    end
    it "semantic/se32.c" do
        expect(semantic_error_message("semantic/se32.c")).to eq "Semantic error: function foo does not return a value"
    end
    it "semantic/se33.c" do
        expect(semantic_error_message("semantic/se33.c")).to eq "Semantic error: 'q' expected 3 arguments, but got 2"
    end
    it "semantic/se34.c" do
        expect(semantic_error_message("semantic/se34.c")).to eq "Semantic error: 'd' expected 2 arguments, but got 3"
    end
    it "semantic/se35.c" do
        expect(semantic_error_message("semantic/se35.c")).to eq "Semantic error: 'fib' expected formal at position 1 to be of type char, but was type int"
    end
    it "semantic/se36.c" do
        expect(semantic_error_message("semantic/se36.c")).to eq "Semantic error: can not cast expression of type int-array to type int"
    end
    it "semantic/se37.c" do
        expect(semantic_error_message("semantic/se37.c")).to eq "syntax error on line 3: can not cast expression to void"
    end
    it "semantic/se38.c" do
        expect(semantic_error_message("semantic/se38.c")).to eq  "Semantic error: char + int is not defined"
    end
end
