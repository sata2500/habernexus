"""
HaberNexus API Pagination
REST API için sayfalama sınıfları.
"""

from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class StandardResultsSetPagination(PageNumberPagination):
    """
    Standart sayfalama sınıfı.
    Varsayılan: 10 öğe/sayfa, maksimum: 100 öğe/sayfa
    """

    page_size = 10
    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response(
            {
                "count": self.page.paginator.count,
                "total_pages": self.page.paginator.num_pages,
                "current_page": self.page.number,
                "next": self.get_next_link(),
                "previous": self.get_previous_link(),
                "results": data,
            }
        )


class LargeResultsSetPagination(PageNumberPagination):
    """
    Büyük veri setleri için sayfalama.
    Varsayılan: 50 öğe/sayfa, maksimum: 500 öğe/sayfa
    """

    page_size = 50
    page_size_query_param = "page_size"
    max_page_size = 500


class SmallResultsSetPagination(PageNumberPagination):
    """
    Küçük veri setleri için sayfalama.
    Varsayılan: 5 öğe/sayfa, maksimum: 20 öğe/sayfa
    """

    page_size = 5
    page_size_query_param = "page_size"
    max_page_size = 20
