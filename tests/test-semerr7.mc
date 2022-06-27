//OPIS: vracanje drugog tipa unije iz funkcije od navedenog povratnog tipa

union Pas {
    int a;
};

union Maca {
    int a;
};

union Pas func() {
    union Maca maca;
    return maca;
}

int main() {
    union Pas pas;
    pas = func();

    return 0;
}