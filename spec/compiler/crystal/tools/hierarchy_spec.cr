require "../../../spec_helper"

describe Crystal::TextHierarchyPrinter do
  it "works" do
    program = semantic(<<-CRYSTAL).program
      class Foo
      end

      class Bar < Foo
      end
      CRYSTAL

    output = String.build { |io| Crystal.print_hierarchy(program, io, "ar$", "text") }
    output.should eq(<<-EOS)
    - class Object (4 bytes)
      |
      +- class Reference (4 bytes)
         |
         +- class Foo (4 bytes)
            |
            +- class Bar (4 bytes)\n
    EOS
  end

  it "shows correct size for Bool member" do
    program = semantic(<<-CRYSTAL).program
      struct Foo
        @x = true
      end
      CRYSTAL

    output = String.build { |io| Crystal.print_hierarchy(program, io, "Foo", "text") }
    output.should eq(<<-EOS)
    - class Object (4 bytes)
      |
      +- struct Value (0 bytes)
         |
         +- struct Struct (0 bytes)
            |
            +- struct Foo (1 bytes)
                   @x : Bool (1 bytes)\n
    EOS
  end

  it "shows correct size for Proc inside extern struct" do
    program = semantic(<<-CRYSTAL).program
      @[Extern]
      struct Foo
        @x = uninitialized ->
      end

      lib Bar
        struct Foo
          x : Int32 -> Int32
        end
      end
      CRYSTAL

    output = String.build { |io| Crystal.print_hierarchy(program, io, "Foo", "text") }
    output.should eq(<<-EOS)
    - class Object (4 bytes)
      |
      +- struct Value (0 bytes)
         |
         +- struct Struct (0 bytes)
            |
            +- struct Bar::Foo (8 bytes)
            |      @x : Proc(Int32, Int32) (8 bytes)
            |
            +- struct Foo (8 bytes)
                   @x : Proc(Nil) (8 bytes)\n
    EOS
  end
end

describe Crystal::JSONHierarchyPrinter do
  it "works" do
    program = semantic(<<-CRYSTAL).program
      class Foo
      end

      class Bar < Foo
      end
      CRYSTAL

    output = String.build { |io| Crystal.print_hierarchy(program, io, "ar$", "json") }
    JSON.parse(output).should eq(JSON.parse(<<-EOS))
    {
      "name": "Object",
      "kind": "class",
      "size_in_bytes": 4,
      "sub_types": [
        {
          "name": "Reference",
          "kind": "class",
          "size_in_bytes": 4,
          "sub_types": [
            {
              "name": "Foo",
              "kind": "class",
              "size_in_bytes": 4,
              "sub_types": [
                {
                  "name": "Bar",
                  "kind": "class",
                  "size_in_bytes": 4,
                  "sub_types": []
                }
              ]
            }
          ]
        }
      ]
    }
    EOS
  end
end
