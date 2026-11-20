//
//  testsBaseCampLogistics.swift
//  DeepBeyondEarth
//
//  Created by Валерия Пономарева on 18.11.2026.
//

import Foundation

func runBaseCampStorageTests() {
    var storage = BaseCampStorage(maxCapacity: 100)
    // Positive scenario
    do {
        // Arrenge - подготовка данных
        assert(storage.currentLoad == 0, "Initial  загрузка склада must be 0")
        
        // Act (действие)
        try storage.receive(name: "Oxygen", amount: 20)
        try storage.receive(name: "Food", amount: 12)
        try storage.receive(name: "Sensor", amount: 5)
        
        try storage.dispatch(name: "Sensor", amount: 5)
        
        assert(storage.currentLoad == 32, "Expected reseive 32")
        assert(storage.resources["Sensor"] == nil, "Key 'Sensor' must be dispatch")
        
        assert(storage.report() == "Storage: 32/100, free: 68, items: Food(12), Oxygen(20)", "Incorrect format of report")
        print("✅ Позитивный тест пройден!")
    } catch {
        assertionFailure("❌ Неожиданная ошибка в позитивном тесте: \(error)")
    }
    // 🐞 Пустой report — em dash
    let empty = BaseCampStorage(maxCapacity: 500)
    assert(empty.report() == "Storage: 0/500, free: 500, items: —", "Empty report format")
    
    // 🐞 emptyName — receive
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: "   ", amount: 10)
        assertionFailure("Expected emptyName")
    } catch LogisticsError.emptyName {} catch { assertionFailure("Wrong: \(error)") }
    
    // 🐞 emptyName — dispatch
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.dispatch(name: "  ", amount: 5)
        assertionFailure("Expected emptyName")
    } catch LogisticsError.emptyName {} catch { assertionFailure() }
    
    // 🐞 invalidAmount — 0
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: "Water", amount: 0)
        assertionFailure("Expected invalidAmount")
    } catch LogisticsError.invalidAmount(let a) { assert(a == 0) } catch { assertionFailure() }
    
    // 🐞 invalidAmount — -5
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: "Water", amount: -5)
        assertionFailure("Expected invalidAmount")
    } catch LogisticsError.invalidAmount(let a) { assert(a == -5) } catch { assertionFailure() }
    
    // 🐞 capacityExceeded
    do {
        var s = BaseCampStorage(maxCapacity: 10)
        try s.receive(name: "Water", amount: 11)
        assertionFailure("Expected capacityExceeded")
    } catch LogisticsError.capacityExceeded(let free, let req) {
        assert(free == 10); assert(req == 11)
    } catch { assertionFailure() }
    
    // 🐞 resourceNotFound
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.dispatch(name: "Gold", amount: 1)
        assertionFailure("Expected resourceNotFound")
    } catch LogisticsError.resourceNotFound(let n) { assert(n == "Gold") } catch { assertionFailure() }
    
    // 🐞 insufficientStock
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: "Food", amount: 5)
        try s.dispatch(name: "Food", amount: 10)
        assertionFailure("Expected insufficientStock")
    } catch LogisticsError.insufficientStock(let a, let r) {
        assert(a == 5); assert(r == 10)
    } catch { assertionFailure() }
    
    // 🐞 trim — " RTG " → "RTG"
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: " RTG ", amount: 2)
        assert(s.resources["RTG"] == 2)
        assert(s.resources[" RTG "] == nil)
        try s.dispatch(name: "RTG", amount: 1)
        assert(s.resources["RTG"] == 1)
    } catch { assertionFailure() }
    
    // 🐞 partial dispatch — остаток не 0, ключ остался
    do {
        var s = BaseCampStorage(maxCapacity: 100)
        try s.receive(name: "Water", amount: 10)
        try s.dispatch(name: "Water", amount: 3)
        assert(s.resources["Water"] == 7)
    } catch { assertionFailure() }
}
/**
 ✅ Позитивный тест пройден!
 */
