import Vapor

extension Int {

    init(_ boolean: Bool) {

        self = boolean ? 1 : 0
    }
}
