builder.course key: nil do
  builder.code course['courseID']
  builder.name course['courseName']
  builder.numberOfReserves course['totalHits']
  builder.numberOfStudents nil

  course['reserveInfo'].each do |reserve|
    builder.reserve key: reserve['reserveControlUniqueKey'] do
      builder.active
      builder.automaticallySelectCopies

      builder.catalogItem key: reserve['catalogKey'] do
        builder.canHold nil
        builder.holding callNumber: reserve['callNumber'] do
          builder.catalogKey reserve['catalogKey']
          builder.copy barcode: reserve['itemID'] do
            render(partial: '/v2/locations/show', locals: {builder: builder, type: "currentLocation", loc: V2::Location.find(reserve['currentLocation']) })
          end

          builder.itemId reserve['itemID']
          render(partial: '/v2/lists/library', locals: {builder: builder, lib: V2::Library.find_by(code: reserve['library']) })
          builder.status nil
        end
      end
      builder.circRule nil
      builder.keepCopiesAtDesk nil
      builder.numberOfReserves reserve['numberOfCopies']
      builder.status nil
    end
  end
end
