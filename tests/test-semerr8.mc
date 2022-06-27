//OPIS: Definisanje unije unutar unije

union Unija {
    int a;
};

union unijaUuniji {
    int a;
    union Unija u;
};

int main() {
    union unijaUuniji u;

    return 0;
}