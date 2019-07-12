builder.checkout do
  builder.catalog_item key: circ_record['titleKey'] do
    #render(partial: 'v2/items/can_hold', locals: {builder: builder, hold: V2::Checkout.get_can_hold(circ_record)})

    builder.holding callNumber: circ_record['callNumber'], callSequence: 1, holdable: true, shadowed: false do
      builder.catalogKey circ_record['titleID']
      builder.copy copyNumber: circ_record['copyNumber'],
                   currentPeriodical: false,
                   barCode: circ_record['itemID'], shadowed: false do

        builder.circulate nil
        builder.currentLocation nil
        builder.homeLocation nil
        render(partial: 'v2/item_types/show', locals: {builder: builder, item_type: V2::ItemType.find('displayName', circ_record['itemTypeID'])})
        builder.lastCheckout nil
      end
      builder.itemID circ_record['itemID']
      render(partial: '/v2/lists/library', locals: {builder: builder,
                    lib: V2::Library.find_by(code: circ_record['itemLibraryID']) }
            )

      builder.shelvingKey circ_record['callNumber']
    end
    builder.status 0

  end
  builder.circulationRule nil
  builder.dateCharged circ_record['checkoutDate']
  builder.dueDate circ_record['dueDate']
  builder.dateRecalled circ_record['recallDate']
  builder.dateRenewed circ_record['lastRenewedDate']
  builder.key nil
  builder.numberOverdueNotices circ_record['overdueNoticesSent']
  builder.numberRecallNotices circ_record['recallNoticesSent']
  builder.numberRenewals circ_record['renewals']
  builder.isOverdue circ_record['overdue']
  builder.canRenew messageCode: nil, name: nil, value: nil do
    builder.message nil
  end
  builder.status 0
end
