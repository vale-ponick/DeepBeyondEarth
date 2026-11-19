//
//  readmeBaseCampLogistics.md
//  DeepBeyondEarth
//
//  Created by Валерия Пономарева on 18.11.2026.
//

import Foundation
 
ТТЗ №1: Склад базового лагеря - 'ArtemisBaseCamp'

Отрабатываемые связки:
    5️⃣ Code Structuring (mutating, extension, инкапсуляция состояния)

    6️⃣ Errors & Handling (enum Error, throws, do-catch)

    9️⃣ Clean Code (защита свойств через private(set), разделение логики и вывода)

1. Контекст и правила системы
На Южном полюсе Луны разворачивается модуль снабжения базового лагеря 'Артемида'. Грузовой шлюз принимает герметичные контейнеры с ресурсами (вода, кислород, научное оборудование) и выдает их экипажу. Из-за жёстких ограничений по массе и объёму складской отсек имеет строгий лимит вместимости, а бортовой компьютер блокирует любые некорректные операции приёмки и выдачи. Внутри модели запрет использования print() - методы тольео меняют данные или выбрасывают ошибки. Очистка пробелов по краям (trim) выаолняется ДО проверки имени.

2. Архитектурные требования
А. Перечисление ошибок LogisticsError: LocalizedError — строго 5 кейсов
#    Кейс    Когда возникает
1    emptyName    имя после trim — пустое название груза (или строка только из пробелов) - ПОСЛЕ обрезкт пробелов по краям
2    invalidAmount(amount: Int)    количество <= 0 - некорректное кол-во
3    capacityExceed(available: Int, requested: Int)  превышение max вместимости склада при приемке - сумма текущего груза + нового > maxCapacity
4    resourceNotFound(name: String)   попытка выдать ресурс, ключа которого вообще нет на сскладе
5    insufficientStock(available: Int, requested: Int)    ЕСТЬ ресурс на складе, НО остатка НЕ хватает при выдаче < amount
errorDescription — для каждого кейса.

Б. Модель склада 'BaseCampStorage'
Свойства(хранение):

    let maxCapacity: Int — max вместимость - задаётся при создании, закрыта на запись private(set)
    private(set) var inventory: [String: Int]   — словарь ресурсов, закрыт на запись извне

Вычисляемык свойства - Computed properties:

    var currentLoad: Int — текущая загрузка  - сумма всех единиц ресурсов на складе)
    var availableSpace: Int - свободное место (остаток до max) = maxCapacity - currentLoad
    var isFull: Bool - TRUE, если свободного места 0  availableSpase == 0
В. Методы управления (mutating + throws)

receive(name: String, amount: Int) throws: - проверяет имя, кол-во Ю 0 и наличие свободного места. Прибавляет груз в словарь.
    Барьеры: 1. очистка пробелов(trim) и проверка !key.isEmpty
             2. amount > 0 (invalidAmount)
             3. currentLoad + amount <= maxCapacity

    let key = name.trimmingCharacters(in: .whitespaces) — trim до проверки;

    guard !key.isEmpty → throw .emptyName;

    guard amount > 0 → throw .invalidAmount(amount:);

    guard currentLoad + amount <= maxCapacity → throw .capacityExceeded(available: freeSpace, requested: amount);

    resources[key, default: 0] += amount — в словарь идёт key (trimmed).

dispatch(name: String, amount: Int) throws: - ВЫДАЧА - проверяет имя, кол-во Ю 0, наличие ключа и достаточный остаток. Вычитает груз. ВАЖНО: если остаток стал < 0 то ключ удаляется из словаря.

    let key = name.trimmingCharacters(in: .whitespaces);

    guard !key.isEmpty → throw .emptyName;

    guard amount > 0 → throw .invalidAmount(amount:);

    guard let stock = resources[key] → throw .resourceNotFound(name: key);

    guard stock >= amount → throw .insufficientStock(available: stock, requested: amount);

    if stock == amount { resources.removeValue(forKey: key) } else { resources[key] = stock - amount } — ключ удаляется при нуле.

    ВАЖНО: print() внутри модели запрещён — только throw или изменение состояния.

Г. Расширение - extension BaseCampStorage
func report() -> String — метод формирования текст. отчета о состоянии склада (занято/свободно/список позиций) формат фиксирован: возвращает ЕДИНУЮ строку состояния склада

"Storage: 120/500, free: 380, items: RTG(2), Food(10), Water(5)"
если словарь пуст: "Storage: 0/500, free: 500, items: —";

позиции — через ,, в формате name(count).

3. План работы
Псевдокод — выполнен (см. раздел 4 ниже). Отдельно писать не нужно.

    baseCampLogistics.swift — реализация LogisticsError и BaseCampStorage полностью самостоятельно.

    testsBaseCampLogistics.swift — проверки всех позитивных и негативных сценариев.

4. Алгоритмы (IPO) — для справки
receive (Вход → Барьеры → Изменение состояния)

Вход: name, amount
Барьер 1: trim(name) → key; key не пуст?
Барьер 2: amount > 0?
Барьер 3: currentLoad + amount <= maxCapacity?
Действие: resources[key, default: 0] += amount

dispatch

Вход: name, amount
Барьер 1: trim(name) → key; key не пуст?
Барьер 2: amount > 0?
Барьер 3: resources[key] существует?
Барьер 4: resources[key] >= amount?

Действие:
  если stock == amount → resources.removeValue(forKey: key)
  иначе → resources[key] = stock - amount

5. Чек-лист тестов  - testsBaseCampLogistics.swift
Позитивные:

    Успешная приёмка — добавление нового ресурса + пополнение существующего. Приемка имени с пробелами по краям  - "  water  " -> as "water"

    Частичная выдача — остаток уменьшается, ключ остаётся в словаре.

    Полная выдача под ноль — остаток обнуляется, ключ удаляется из словаря.

    Негативные — по одному do/catch (или проверке) на каждый из 5 кейсов LogisticError:
    
    Проверка report() - сверка формата строки для пустого и заполненого склада

Кейс    Что проверить
emptyName    receive(name: " ", amount: 10) и dispatch
invalidAmount    amount: 0 и amount: -5
capacityExceeded    currentLoad + amount > maxCapacity
resourceNotFound    dispatch несуществующего ключа
insufficientStock    dispatch больше, чем есть
Дополнительно: trim — receive(name: " RTG ", amount: 2), затем dispatch(name: "RTG", amount: 1) — должен найти тот же ключ.



Что важно учесть, чтобы не потерять самостоятельность

Поскольку в этой версии внутри пункта 2.В уже прописаны конкретные строчки синтаксиса Swift (а не только логика), при переносе в baseCampLogistics.swift используй их как контрольный чек-лист, а не как текст для слепого копирования:
• Сначала сверяйся со схемой IPO (раздел 4). Пиши код в Xcode, глядя на логику барьеров из раздела 4, и только если застрянешь в синтаксисе — подсматривай в раздел 2.
• Обрати внимание на инициатор (инициализатор) структуры. В BaseCampStorage свойство resources имеет модификатор private(set). Чтобы при создании склада тебе не приходилось каждый раз передавать пустой словарь снаружи, задай ему значение по умолчанию прямо при объявлении (private(set) var resources: [String: Int] = [:]). Тогда экземпляр можно будет создать чисто: BaseCampStorage(maxCapacity: 500).
• Учти порядок элементов в report(). В Swift словарь (Dictionary) не гарантирует порядок ключей. Если при формировании строки items: RTG(2), Food(10), Water(5) ты захочешь, чтобы ресурсы в отчете всегда шли в предсказуемом алфавитном порядке (это сильно упрощает автоматическую проверку строки в тестах), отсортируй пары словаря по ключу перед склейкой.
