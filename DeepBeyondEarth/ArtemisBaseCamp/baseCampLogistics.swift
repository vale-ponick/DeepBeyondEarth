//
//  baseCampLogistics.swift
//  DeepBeyondEarth
//
//  Created by Валерия Пономарева on 16.11.2026.
//

import Foundation

enum LogisticsError: LocalizedError {
    case emptyName // пустое название груза
    case invalidAmount(amount: Int) // некорректное кол-во груза <= 0
    case capacityExceeded(freeSpace: Int, requested: Int) // превышение max вместимости склада при приемке
    case insufficientStock(available: Int, requested: Int) // есть ресурс, НО нехватка его остатка при выдаче
    case resourceNotFound(name: String) // попытка выдать ресурс, ключа которого вообще НЕТ на складе
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Resource name is empty"
        case .invalidAmount(let amount):
            return "Invalid amount: \(amount). Must be > 0"
        case .capacityExceeded(let freeSpace, let requested):
            return "Not enough space: free \(freeSpace), requested \(requested)"
        case .insufficientStock(let available, let requested):
            return "Not enough stock: available \(available), requested \(requested)"
        case .resourceNotFound(let name):
            return "Resource '\(name)' not found"
        }
    }
}

struct BaseCampStorage {
    let maxCapacity: Int // max вместимость
    private(set) var resources: [String: Int] = [:] // склад ресурсов
    
    var currentLoad: Int { // текущая загрузка склада = computed property
        resources.values.reduce(0, +) // сумма всех единиц ресурсов на складе
    }
    
    var freeSpace: Int {
        maxCapacity - currentLoad // оставшееся свободное место
    }
    
    var isFull: Bool { // проверка: равно ли 0 свободное место?
        freeSpace == 0
    }
    
    mutating func receive(name: String, amount: Int) throws {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        
        guard !cleanName.isEmpty else {
            throw LogisticsError.emptyName
        }
        guard amount > 0 else {
            throw LogisticsError.invalidAmount(amount: amount)
        }
        guard currentLoad + amount <= maxCapacity else {
            throw LogisticsError.capacityExceeded(freeSpace: freeSpace, requested: amount)
        }
        
        resources[cleanName, default: 0] += amount
    }
    
    mutating func dispatch(name: String, amount: Int) throws {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        
        guard !cleanName.isEmpty else {
            throw LogisticsError.emptyName
        }
        
        guard amount > 0 else {
            throw LogisticsError.invalidAmount(amount: amount)
        }
        
        guard let stock = resources[cleanName] else {
            throw LogisticsError.resourceNotFound(name: cleanName)
        }
        
        guard stock >= amount else {
            throw LogisticsError.insufficientStock(available: stock, requested: amount)
        }
        if stock == amount {
            resources.removeValue(forKey: cleanName)
        } else {
            resources[cleanName] = stock - amount
        }
    }
}
    
    extension BaseCampStorage {
        func report() -> String {
            let itemList = resources.isEmpty ? "—" : resources.sorted { $0.key < $1.key }.map { "\($0.key)(\($0.value))" }.joined(separator: ", ")
            return "Storage: \(currentLoad)/\(maxCapacity), free: \(freeSpace), items: \(itemList)"
    }
}

/* • Два mutating метода с throws:
    • receive(name: String, amount: Int) throws — очищает пробелы (trim), проверяет 3 барьера (emptyName, invalidAmount, capacityExceeded) и прибавляет количество к ключу в словаре.
    • dispatch(name: String, amount: Int) throws — очищает пробелы (trim), проверяет 4 барьера (emptyName, invalidAmount, resourceNotFound, insufficientStock), вычитает количество и удаляет ключ из словаря, если остаток стал равен нулю. */
