package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Classe;
import org.isetn.repository.ClasseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/classes")
public class ClasseController {

    @Autowired
    private ClasseRepository classeRepository;

    @GetMapping
    public List<Classe> getAll() {
        return classeRepository.findAll();
    }

    // Classes d'un département donné
    @GetMapping("/departement/{codDept}")
    public List<Classe> getByDepartement(@PathVariable Integer codDept) {
        return classeRepository.findAll().stream()
                .filter(c -> c.getDepartement() != null
                        && codDept.equals(c.getDepartement().getCodDept()))
                .toList();
    }

    @PostMapping
    public Classe add(@RequestBody Classe c) {
        return classeRepository.save(c);
    }

    @PutMapping("/{id}")
    public Classe update(@PathVariable Integer id, @RequestBody Classe c) {
        c.setCodClass(id);
        return classeRepository.save(c);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Integer id) {
        classeRepository.deleteById(id);
    }
}
