require_relative "../code/builtin.rb"

class Temporary < Struct.new(:index)
    def fix_globals locals; end
    def generate_llvm formal_map = nil
        "%#{index}"
    end
end

class Label < Struct.new(:name, :index)
    def fix_globals locals; end
    def generate_llvm formal_map = nil
        "#{name}#{index}:"
    end
    def identifier
        "%#{name}#{index}"
    end
end

class Allocator
    def initialize
        @next_temporary = 0
        @next_label = 0
    end
    def new_temporary
        Temporary.new (@next_temporary += 1)
    end
    def new_label name
        Label.new name, (@next_label += 1)
    end
end

class Id < Struct.new(:name, :global)
    def fix_globals locals
        self.global = !locals.include?(name)
    end
    def generate_llvm formal_map = nil
        if global
            return "@#{name}"
        elsif formal_map and formal_map.include? name
            return formal_map[name]
        else
            return "%#{name}"
        end
    end
end

class Constant < Struct.new(:type, :value)
    def fix_globals locals; end
    def generate_llvm formal_map = nil
        "#{value}"
    end
end


def generate_ir ast
    builtin = Builtin.new
    ir = Ir.new(ast.generate_ir(builtin, []))
    if builtin.has_header?
        ir.definitions.unshift builtin
    end

    functions = ir.definitions.select { |d| d.instance_of? Function }
    functions.each do |f|
        formals = f.formals.map {|f| f[:name] }
        locals = f.declarations.map { |d| d[:name] }

        f.instructions.each do |i|
            i.fix_globals locals + formals
        end
    end
    ir
end

class Ir < Struct.new(:definitions)
    def generate_llvm formal_map = nil
        code = ""
        definitions.each do |d|
            code << d.generate_llvm
        end
        code
    end
end

class Eval < Struct.new(:destination, :expression);
    def fix_globals locals;
        destination.fix_globals locals
        expression.fix_globals locals
    end
    def generate_llvm formal_map = nil
        "#{destination.generate_llvm} = #{expression.generate_llvm(formal_map)}"
    end
end

class GlobalVariable < Struct.new(:name); end
class GlobalInt < GlobalVariable; def generate_llvm formal_map = nil; "@#{name} = global i32 zeroinitializer\n" end end
class GlobalChar < GlobalVariable; def generate_llvm formal_map = nil; "@#{name} = global i8 zeroinitializer\n" end end

class LocalVariable < Struct.new(:name); end
class LocalInt < LocalVariable; def generate_llvm formal_map = nil; "    %#{name} = alloca i32\n" end end
class LocalChar < LocalVariable; def generate_llvm formal_map = nil; "    %#{name} = alloca i8\n" end end

class GlobalArray < Struct.new(:name, :size); end
class GlobalIntArray < GlobalArray; def generate_llvm formal_map = nil; "@#{name} = global [#{size} x i32] zeroinitializer\n" end end
class GlobalCharArray < GlobalArray; def generate_llvm formal_map = nil; "@#{name} = global [#{size} x i8] zeroinitializer\n" end end

class LocalArray < Struct.new(:name, :size); end
class LocalIntArray < LocalArray; def generate_llvm formal_map = nil; "    %#{name} = alloca [#{size} x i32]\n" end end
class LocalCharArray < LocalArray; def generate_llvm formal_map = nil; "    %#{name} = alloca [#{size} x i8]\n" end end

class FormalArgument < Struct.new(:name, :type, :temporary)
    def generate_llvm formal_map = nil
        return "" if type.instance_of? Pointer or temporary == :YOU_SHALL_NOT_GENERATE_ALLOCATIONS
        "    #{temporary.generate_llvm} = alloca #{type}\n" +
        "    store #{type} %#{name}, #{type}* #{temporary.generate_llvm}\n"
    end
end

class Function < Struct.new(:name, :type, :formals, :declarations, :instructions)
    def generate_llvm formal_map = nil
        formal_allocation = ""
        formal_to_temporary = {}
        formal_list = ""
        formals.each do |f|
            # puts "formal type #{type}"
            formal_list += ", " unless formal_list.empty?
            formal_list += "#{f.type} %#{f.name}"
            formal_allocation += f.generate_llvm
            formal_to_temporary[f.name] = f.temporary.generate_llvm unless f.temporary == :YOU_SHALL_NOT_GENERATE_ALLOCATIONS
        end

        header = "\ndefine #{type} @#{name}(#{formal_list}) {\n"

        declaration_list = ""
        declarations.each do |d|
            declaration_list += d.generate_llvm
        end

        instruction_list = formal_allocation
        instructions.each do |i|
            extra_indent = "  " unless i.instance_of? Label
            instruction_list += "  #{extra_indent}" + i.generate_llvm(formal_to_temporary) + "\n"
        end

        header + declaration_list + instruction_list + "}"
    end
end

class Return < Struct.new(:type, :op)
    def fix_globals locals
        op.fix_globals locals unless type == :void
    end
    def generate_llvm formal_map = nil
        unless type == :void
            "ret #{type} #{op.generate_llvm(formal_map)}"
        else
            "ret #{type}"
        end
    end
end

class Binop < Struct.new(:type, :op1, :op2)
    def fix_globals locals
        op1.fix_globals locals
        op2.fix_globals locals
    end
    def generate_llvm formal_map = nil
        class_to_instruction = {
            Add         => "add",
            Sub         => "sub",
            Mul         => "mul",
            Div         => "sdiv",
            LessThen    => "icmp slt",
            GreaterThen => "icmp sgt",
            LessEqual   => "icmp sle",
            GreaterEqual=> "icmp sge",
            NotEqual    => "icmp ne",
            Equal       => "icmp eq",
            And         => "and",
            Or          => "or",
        }
        "#{class_to_instruction[self.class]} #{type} #{op1.generate_llvm(formal_map)}, #{op2.generate_llvm(formal_map)}"
    end
end

class Add          < Binop; end
class Sub          < Binop; end
class Mul          < Binop; end
class Div          < Binop; end
class LessThen     < Binop; end
class GreaterThen  < Binop; end
class LessEqual    < Binop; end
class GreaterEqual < Binop; end
class NotEqual     < Binop; end
class Equal        < Binop; end
class And          < Binop; end
class Or           < Binop; end

class ArrayElement < Struct.new(:type, :name, :num_elements, :index)
    def fix_globals locals
        # global = locals.include? name
        @global = !locals.include?(name)
    end
    def identifier
        "#{@global ? "@" : "%"}#{name}"
    end
    def generate_llvm formal_map = nil
        if num_elements
            array_type = "[#{num_elements} x #{type}]*"
            "getelementptr inbounds #{array_type} #{identifier}, i32 0, i32 #{index.generate_llvm(formal_map)}"
        else
            array_type = "#{type}*" unless num_elements
            "getelementptr inbounds #{array_type} #{identifier}, i32 #{index.generate_llvm(formal_map)}"
        end
    end
end

class Not < Struct.new(:type, :op)
    def fix_globals locals
        op.fix_globals locals
    end
    def generate_llvm formal_map = nil
        "icmp eq #{type} #{op.generate_llvm(formal_map)}, 0"
    end
end
class Cast < Struct.new(:op, :from, :to)
    def fix_globals locals
        op.fix_globals locals
    end
    def generate_llvm formal_map = nil
        instruction = (llvm_type_size(from) < llvm_type_size(to)) ? "sext" : "trunc"
        "#{instruction} #{from} #{op.generate_llvm(formal_map)} to #{to}"
    end
end

class ZeroExtend < Struct.new(:op, :from, :to)
    def fix_globals locals
        op.fix_globals locals
    end
    def generate_llvm formal_map = nil
        raise "unable to zero extend to smaller type" if (llvm_type_size(from) > llvm_type_size(to))
        "zext #{from} #{op.generate_llvm(formal_map)} to #{to}"
    end
end

class Load < Struct.new(:type, :source);
    def fix_globals locals
        source.fix_globals locals
    end
    def generate_llvm formal_map = nil
        pointer = type.instance_of?(Pointer) ? "" : "*"
        "load #{type}#{pointer} #{source.generate_llvm(formal_map)}"
    end
end

class Store < Struct.new(:type, :destination, :source)
    def fix_globals locals
        destination.fix_globals locals
        source.fix_globals locals
    end
    def generate_llvm formal_map = nil
        "store #{type} #{source.generate_llvm(formal_map)}, #{type}* #{destination.generate_llvm(formal_map)}"
    end
end
class Call < Struct.new(:type, :name, :argument_list)
    def fix_globals locals;
        name.fix_globals locals
    end
    def generate_llvm formal_map = nil

        arguments = argument_list.map do |a|
            "#{a[:type]} #{a[:id].generate_llvm(formal_map)}"
        end
        "call #{type} #{name.generate_llvm} (#{arguments.join(", ")})"
    end
end

class Jump < Struct.new(:label)
    def fix_globals locals; end
    def generate_llvm formal_map = nil
        "br label #{label.identifier}"
    end
end

class Branch < Struct.new(:condition, :true_branch, :false_branch)
    def fix_globals locals
        condition.fix_globals locals
    end
    def generate_llvm formal_map = nil
        "br i1 #{condition.generate_llvm(formal_map)}, label #{true_branch.identifier}, label #{false_branch.identifier}"
    end
end

class Compare < Struct.new(:type, :value)
    def fix_globals locals
        value.fix_globals locals
    end
    def generate_llvm formal_map = nil
        "icmp ne #{type} #{value.generate_llvm(formal_map)}, 0"
    end
end
