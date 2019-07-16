active = hold['holdStatus'] == 2 ? true : false
type = hold['recallStatus'] == 'NO' ? 'Hold' : 'Recall'

builder.hold active: active, level: 'copy', type: type do
  builder.catalogItem key: hold['titleKey'] do
    # most item info is not present in a hold
    builder.canHold nil
    builder.holding callSequence: 0, holdable: false, shadowed: nil do
      builder.catalogKey hold['titleKey']
      render(partial: '/v2/lists/library', locals: {builder: builder,
              lib: V2::Library.find_by(code: hold['itemLibraryID']) }
            )
    end
    builder.status 1 # not used?
  end
  builder.dateNotified nil
  builder.datePlaced hold['placedDate']
  builder.dateRecalled nil
  builder.inactiveReason hold['holdIncactiveReasonDescription']
  builder.key hold['holdKey']
  render(partial: '/v2/holds/pickup_library',
         locals: {builder: builder,
                  lib: V2::Library.find_by(code: hold['pickupLibraryID'])
                 }
        )
  builder.priority 100 #default
end
