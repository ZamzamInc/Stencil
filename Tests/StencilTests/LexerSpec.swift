import Spectre
@testable import Stencil
import XCTest

class LexerTests: XCTestCase {
  func testLexer() {
    describe("Lexer") {
      func makeSourceMap(_ token: String, for lexer: Lexer, options: String.CompareOptions = []) -> SourceMap {
        guard let range = lexer.templateString.range(of: token, options: options) else { fatalError("Token not found") }
        return SourceMap(location: lexer.rangeLocation(range))
      }

      $0.it("can tokenize text") {
        let lexer = Lexer(templateString: "Hello World")
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 1
        try expect(tokens.first) == .text(value: "Hello World", at: makeSourceMap("Hello World", for: lexer))
      }

      $0.it("can tokenize a comment") {
        let lexer = Lexer(templateString: "{# Comment #}")
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 1
        try expect(tokens.first) == .comment(value: "Comment", at: makeSourceMap("Comment", for: lexer))
      }

      $0.it("can tokenize a variable") {
        let lexer = Lexer(templateString: "{{ Variable }}")
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 1
        try expect(tokens.first) == .variable(value: "Variable", at: makeSourceMap("Variable", for: lexer))
      }

      $0.it("can tokenize a token without spaces") {
        let lexer = Lexer(templateString: "{{Variable}}")
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 1
        try expect(tokens.first) == .variable(value: "Variable", at: makeSourceMap("Variable", for: lexer))
      }

      $0.it("can tokenize unclosed tag by ignoring it") {
        let templateString = "{{ thing"
        let lexer = Lexer(templateString: templateString)
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 1
        try expect(tokens.first) == .text(value: "", at: makeSourceMap("{{ thing", for: lexer))
      }

      $0.it("can tokenize a mixture of content") {
        let templateString = "My name is {{ myname }}."
        let lexer = Lexer(templateString: templateString)
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 3
        try expect(tokens[0]) == Token.text(value: "My name is ", at: makeSourceMap("My name is ", for: lexer))
        try expect(tokens[1]) == Token.variable(value: "myname", at: makeSourceMap("myname", for: lexer))
        try expect(tokens[2]) == Token.text(value: ".", at: makeSourceMap(".", for: lexer))
      }

      $0.it("can tokenize two variables without being greedy") {
        let templateString = "{{ thing }}{{ name }}"
        let lexer = Lexer(templateString: templateString)
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 2
        try expect(tokens[0]) == Token.variable(value: "thing", at: makeSourceMap("thing", for: lexer))
        try expect(tokens[1]) == Token.variable(value: "name", at: makeSourceMap("name", for: lexer))
      }

      $0.it("can tokenize an unclosed block") {
        let lexer = Lexer(templateString: "{%}")
        _ = lexer.tokenize()
      }

      $0.it("can tokenize incorrect syntax without crashing") {
        let lexer = Lexer(templateString: "func some() {{% if %}")
        _ = lexer.tokenize()
      }

      $0.it("can tokenize an empty variable") {
        let lexer = Lexer(templateString: "{{}}")
        _ = lexer.tokenize()
      }

      $0.it("can tokenize with new lines") {
        let templateString = """
          My name is {%
              if name
               and
              name
          %}{{
          name
          }}{%
          endif %}.
          """
        let lexer = Lexer(templateString: templateString)
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 5
        try expect(tokens[0]) == Token.text(value: "My name is ", at: makeSourceMap("My name is", for: lexer))
        try expect(tokens[1]) == Token.block(value: "if name and name", at: makeSourceMap("{%", for: lexer))
        try expect(tokens[2]) == Token.variable(value: "name", at: makeSourceMap("name", for: lexer, options: .backwards))
        try expect(tokens[3]) == Token.block(value: "endif", at: makeSourceMap("endif", for: lexer))
        try expect(tokens[4]) == Token.text(value: ".", at: makeSourceMap(".", for: lexer))
      }

      $0.it("can tokenize escape sequences") {
        let templateString = "class Some {{ '{' }}{% if true %}{{ stuff }}{% endif %}"
        let lexer = Lexer(templateString: templateString)
        let tokens = lexer.tokenize()

        try expect(tokens.count) == 5
        try expect(tokens[0]) == Token.text(value: "class Some ", at: makeSourceMap("class Some ", for: lexer))
        try expect(tokens[1]) == Token.variable(value: "'{'", at: makeSourceMap("'{'", for: lexer))
        try expect(tokens[2]) == Token.block(value: "if true", at: makeSourceMap("if true", for: lexer))
        try expect(tokens[3]) == Token.variable(value: "stuff", at: makeSourceMap("stuff", for: lexer))
        try expect(tokens[4]) == Token.block(value: "endif", at: makeSourceMap("endif", for: lexer))
      }
    }
  }
}
