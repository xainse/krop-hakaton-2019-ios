//
//  ListViewModel.swift
//  KropHackathon
//
//  Created by Tetiana Nieizviestna on 04.12.2019.
//  Copyright © 2019 onix. All rights reserved.
//

import Foundation
import RxSwift

enum ListScreenType {
    case serviceDetails
    case hospitals
}

protocol ListViewModelType {
    var didLoadData: (() -> Void)? { get set }
    var didLoadFailed: ((String) -> Void)? { get set }
    
    var screenType: ListScreenType { get set }
    var screenTitle: String { get set }
    
    var serviceModel: ServiceTypeModel { get set }
    var serviceDetailsModels: [String] { get }
    var hospitalModels: [HospitalModel] { get }
    
    func openHospitals(row: Int)
    func openDetails(row: Int)
    func goBack()
}

final class ListViewModel: ListViewModelType {
    
    private let coordinator: ListCoordinatorType
    private let networkService: NetworkServiceType
    private let disposeBag = DisposeBag()
    
    var didLoadData: (() -> Void)?
    var didLoadFailed: ((String) -> Void)?
    
    var screenType: ListScreenType
    var screenTitle: String
    var serviceModel: ServiceTypeModel
    
    var serviceDetailsModels: [String] = []
    var hospitalModels: [HospitalModel] = []
    
    init(_ coordinator: ListCoordinatorType, serviceHolder: ServiceHolder, screenType: ListScreenType = .serviceDetails, serviceTypeModel: ServiceTypeModel) {
        self.coordinator = coordinator
        networkService = serviceHolder.get(by: NetworkServiceType.self)
        
        self.screenType = screenType
        self.screenTitle = serviceTypeModel.name
        serviceModel = serviceTypeModel
        
        switch screenType {
        case .serviceDetails:
            serviceDetailsModels = serviceModel.services
            self.didLoadData?()
        case .hospitals:
            networkService.hospitalsObserver.subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let model):
                    self?.hospitalModels = []
                    model.forEach { element in
                        self?.hospitalModels.append(HospitalModel.init(model: element))
                    }
                    self?.didLoadData?()
                case .failure(error: let error):
                    self?.didLoadFailed?(error)
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func openHospitals(row: Int) {
        networkService.getHospitals(type: serviceDetailsModels[row])
        
        coordinator.openHospitals(model: serviceModel)
    }
    
    func openDetails(row: Int) {
        networkService.getHospital(id: hospitalModels[row].id)
        coordinator.openDetails()
    }
    
    func goBack() {
        coordinator.goBack()
    }
    
}
